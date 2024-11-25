#!/bin/bash
# This file sets up a new Agave voting validator
# Builds Solana from source and optimizes the validator
# for the specifications of each machine.

# Exit on error
set -euo pipefail

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

# Function to install prerequisites
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

# Function to install Solana
install_solana() {
    local install_dir="${1:-$HOME/solana}"
    echo "Installing Solana in $install_dir..."

    mkdir -p "$install_dir"
    cd "$install_dir"

    local tarball="v${SOL_VERSION}.tar.gz"
    wget "https://github.com/anza-xyz/agave/archive/refs/tags/$tarball"
    tar xvf "$tarball"
    cd "agave-$SOL_VERSION"

    ./scripts/cargo-install-all.sh .

    append_to_path "$PWD/bin"
    agave-install init "$SOL_VERSION"
    echo "Solana installed successfully."
}

# Function to mount drives
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

# Function to optimize system settings
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
        echo "Added DefaultLimitNOFILE to $system_conf."
    else
        echo "DefaultLimitNOFILE is already set in $system_conf."
    fi

    sudo systemctl daemon-reload
    echo "System tuning complete."
}

setup_service() {
    local service_file="/etc/systemd/system/sol.service"

    sudo bach -c "cat > $service_file <<EOF
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
LogRateLimitIntervalSec=0
Environment="PATH=/bin:/usr/bin:/home/sol/.local/share/solana/install/active_release/bin"
ExecStart=/home/sol/bin/run.sh

[Install]
WantedBy=multi-user.target
EOF"
    sudo systemctl enable --now sol
    echo "Solana service setup complete."
}

setup_log() {
    # Setup log rotation

    cat >logrotate.sol <<EOF
/home/sol/agave-validator.log {
  rotate 7
  daily
  missingok
  postrotate
    systemctl kill -s USR1 sol.service
  endscript
}
EOF
    sudo cp logrotate.sol /etc/logrotate.d/sol
    systemctl restart logrotate.service

}

# Main script execution
main() {
    # Ensure script is run as the "sol" user
    if [[ "$(whoami)" != "sol" ]]; then
        echo "Please run this script as the 'sol' user or switch to the 'sol' user using 'su - sol'."
        exit 1
    fi

    # Set Solana version from file
    if [[ ! -f SOL_VERSION.txt ]]; then
        echo "SOL_VERSION.txt file not found. Please create it with the required Solana version."
        exit 1
    fi

    export SOL_VERSION=$(cat SOL_VERSION.txt)
    echo "Using Solana version: $SOL_VERSION"

    # Install prerequisites
    install_prerequisites

    # Install Solana
    install_solana "$HOME/solana"

    # Mount drives (customize drives as needed)
    mount_drives $1 $2

    # Tune the system
    tune_system

    # Setup Solana service
    setup_service

    echo "Setup complete. Reboot the system for all changes to take effect."
}

# Run main function
main "$@"
