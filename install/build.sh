#!/bin/bash
# This file sets up a new Agave voting validator
# Builds Solana from source and optimizes the validator
# for the specifications of each machine.

# Exit on error
set -eo pipefail

# Function to append a directory to PATH
append_to_path() {
    local new_dir="$1"                      # Directory to add to PATH
    local target_file="${2:-$HOME/.bashrc}" # Shell config file (default: ~/.bashrc)

    if ! grep -q "export PATH=.*$new_dir" "$target_file"; then
        echo "export PATH=\"\$PATH:$new_dir\"" >>"$target_file"
        echo "Added $new_dir to PATH permanently in $target_file"
    else
        echo "$new_dir is already in PATH in $target_file"
    fi

    export PATH="$PATH:$new_dir"
    echo "Added $new_dir to PATH in the current shell session"
}

create_sol_user() {
    echo "Creating a new user for Solana..."
    sudo adduser sol
    sudo usermod -aG sudo sol
    echo "User 'sol' created successfully."
}

install_prerequisites() {
    echo "Installing prerequisites..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env

    sudo apt-get update && sudo apt-get install -y \
        build-essential \
        pkg-config \
        libudev-dev \
        llvm \
        libclang-dev \
        protobuf-compiler \
        wget \
        tar

    append_to_path "$HOME/.cargo/bin"
    echo "Prerequisites installed successfully."
}

install_solana() {
    local install_dir="$1"
    local sol_version="$2"

    echo "Installing Solana version $sol_version in $install_dir..."
    mkdir -p "$install_dir"
    cd "$install_dir"

    local tarball="v${sol_version}.tar.gz"
    wget "https://github.com/anza-xyz/agave/archive/refs/tags/$tarball"
    tar xvf "$tarball"
    cd "agave-$sol_version"

    ./scripts/cargo-install-all.sh .

    append_to_path "$PWD/bin"
    echo "Solana installed successfully."
}

mount_drives() {
    local ledger_drive="$1"
    local accounts_drive="$2"

    echo "Formatting and mounting drives..."
    sudo mkfs -t ext4 "$ledger_drive"
    sudo mkfs -t ext4 "$accounts_drive"

    mkdir -p /mnt/ledger /mnt/accounts
    sudo chown -R sol:sol /mnt/ledger /mnt/accounts

    sudo mount "$ledger_drive" /mnt/ledger
    sudo mount "$accounts_drive" /mnt/accounts

    echo "Drives mounted successfully."
}

tune_system() {
    echo "Optimizing system settings..."
    local sysctl_file="/etc/sysctl.d/21-agave-validator.conf"

    sudo bash -c "cat > $sysctl_file <<EOF
# Increase UDP buffer sizes
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728

# Increase memory mapped files limit
vm.max_map_count = 1000000

# Increase number of allowed open file descriptors
fs.nr_open = 1000000
EOF"

    sudo sysctl -p "$sysctl_file"

    local system_conf="/etc/systemd/system.conf"
    if ! grep -q "DefaultLimitNOFILE=1000000" "$system_conf"; then
        sudo bash -c "echo 'DefaultLimitNOFILE=1000000' >> $system_conf"
    fi

    sudo systemctl daemon-reload
    echo "System tuning complete."
}

setup_service() {
    local service_file="/etc/systemd/system/sol.service"
    sudo bash -c "cat > $service_file <<EOF
[Unit]
Description=Solana Validator
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=sol
LimitNOFILE=1000000
ExecStart=/home/solange/bin/validator.sh

[Install]
WantedBy=multi-user.target
EOF"
    sudo systemctl enable --now sol
    echo "Solana service setup complete."
}

# Parse named parameters
parse_args() {
    local args=("$@")
    while [[ $# -gt 0 ]]; do
        case $1 in
        --sol-version)
            SOL_VERSION="$2"
            shift 2
            ;;
        --install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --mount-ledger)
            LEDGER_DRIVE="$2"
            shift 2
            ;;
        --mount-accounts)
            ACCOUNTS_DRIVE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
        esac
    done
}

main() {
    # Default values
    SOL_VERSION="stable"
    INSTALL_DIR="$HOME/solange"
    LEDGER_DRIVE=""
    ACCOUNTS_DRIVE=""

    # Parse named parameters
    parse_args "$@"

    # Check required arguments
    if [[ -z "$LEDGER_DRIVE" || -z "$ACCOUNTS_DRIVE" ]]; then
        echo "Error: Both --mount-ledger and --mount-accounts are required."
        exit 1
    fi

    # Create user
    create_sol_user

    # Install prerequisites
    install_prerequisites

    # Install Solana
    install_solana "$INSTALL_DIR" "$SOL_VERSION"

    # Mount drives
    mount_drives "$LEDGER_DRIVE" "$ACCOUNTS_DRIVE"

    # Tune system
    tune_system

    # Setup service
    setup_service

    echo "Setup complete!"
}

main "$@"
