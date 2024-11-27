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
    # Create a new user sol sudo if it doesn't exist
    if ! id sol &>/dev/null; then
        echo "Creating a new user for Solana..."
        sudo adduser sol
        sudo usermod -aG sudo sol
        sudo passwd sol
        echo "User 'sol' created successfully."
    else
        echo "User 'sol' already exists."
    fi

    # Re-run the script as the sol user if not already running as sol
    # if [[ "$(whoami)" != "sol" ]]; then
    #     echo "Switching to user 'sol'..."
    #     sudo  "$0"
    #     sudo -u sol bash "$0" "$@"
    #     exit
    # fi
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
        tar \
        ntpdate

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

    agave-install init $sol_version
    echo "Solana installed successfully."
}

mount_drives() {
    local ledger_drive="$1"
    local accounts_drive="$2"
    local ledger_dir="${3:-/mnt/ledger}"
    local accounts_dir="${4:-/mnt/accounts}"

    echo "Formatting and mounting drives..."
    sudo mkfs -t ext4 "$ledger_drive"
    sudo mkdir -p $ledger_dir

    sudo mount "$ledger_drive" $ledger_dir
    sudo chown -R sol:sol $ledger_dir

    if [[ "$ledger_drive" != "$accounts_drive" ]]; then
        sudo mkfs -t ext4 "$accounts_drive"
        sudo mkdir -p $accounts_dir
        sudo mount "$accounts_drive" $accounts_dir
        sudo chown -R sol:sol $accounts_dir
    else
        sudo mkdir -p $ledger_dir/ledger
        sudo mkdir -p $ledger_dir/accounts
        sudo chown -R sol:sol $ledger_dir
    fi
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

setup_log() {
    # Ensure the log directory exists with correct permissions
    local log_dir="/home/sol/solange/logs"
    local log_file="$log_dir/agave-validator.log"

    sudo mkdir -p "$log_dir"
    sudo chown -R sol:sol "$log_dir"
    sudo chmod 755 "$log_dir"

    # Ensure the log file exists and is writable
    sudo touch "$log_file"
    sudo chown sol:sol "$log_file"
    sudo chmod 644 "$log_file"

    # Setup log rotation for the log file
    local logrotate_config="/etc/logrotate.d/sol"

    sudo bash -c "cat >$logrotate_config <<EOF
$log_file {
  rotate 7
  daily
  missingok
  notifempty
  compress
  delaycompress
  copytruncate
  postrotate
    systemctl kill -s USR1 sol.service > /dev/null 2>/dev/null || true
  endscript
}
EOF"

    # Restart the logrotate service to apply changes
    sudo systemctl restart logrotate.service

    echo "Log rotation setup complete for $log_file."
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
ExecStartPre=/home/sol/solange/bin/catchup.sh
ExecStart=/home/solange/bin/execute.sh
TimeoutStartSec=600

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
        --ledger-drive)
            LEDGER_DRIVE="$2"
            shift 2
            ;;
        --accounts-drive)
            ACCOUNTS_DRIVE="$2"
            shift 2
            ;;
        --ledger-dir)
            LEDGER_DIR="$2"
            shift 2
            ;;
        --accounts-dir)
            ACCOUNTS_DIR="$2"
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
    SOL_VERSION=$(curl -s https://api.github.com/repos/anza-xyz/agave/releases/latest | jq -r '.tag_name' | sed 's/v//')
    INSTALL_DIR="$HOME/solange"
    LEDGER_DRIVE=""
    ACCOUNTS_DRIVE=""
    LEDGER_DIR="/mnt/ledger"
    ACCOUNTS_DIR="/mnt/accounts"

    # Parse named parameters
    parse_args "$@"

    # Check required arguments
    if [[ -z "$LEDGER_DRIVE" || -z "$ACCOUNTS_DRIVE" ]]; then
        echo "Error: Both --mount-ledger and --mount-accounts are required."
        exit 1
    fi

    # Create user
    su - sol -c create_sol_user

    # Install prerequisites
    su - sol -c install_prerequisites

    # Install Solana
    su - sol -c install_solana "$INSTALL_DIR" "$SOL_VERSION"

    # Mount drives
    su - sol -c mount_drives "$LEDGER_DRIVE" "$ACCOUNTS_DRIVE" "$LEDGER_DIR" "$ACCOUNTS_DIR"

    # Tune system
    su - sol -c tune_system

    # Setup log rotation
    su - sol -c setup_log

    # Setup service
    su - sol -c setup_service

    echo "Setup complete!"
}

main "$@"
