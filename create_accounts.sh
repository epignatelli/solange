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

install_prerequisites() {
    # install prerequisites
    echo "Installing prerequisites..."
    echo "Installing Rust..."
    sh -c "$(curl -sSfL https://release.anza.xyz/v2.1.0/install)"
    echo "Installing Solana..."
    sol_version=$(cat SOL_VERSION.txt)
    curl --proto '=https' --tlsv1.2 -sSf https://release.anza.xyz/v$sol_version/install | sh -s -- -y
    append_to_path "$HOME/.cargo/bin"
    echo "Prerequisites installed successfully."
}

set_network() {
    # set network to devnet, testnet, or mainnet
    echo "Setting default network..."
    # use testnet by default
    case $1:-"testnet" in
    "devnet")
        solana config set --url https://api.devnet.solana.com
        echo "Default network set to devnet."
        ;;
    "testnet")
        solana config set --url https://api.testnet.solana.com
        echo "Default network set to testnet."
        ;;
    "mainnet")
        solana config set --url https://api.mainnet-beta.solana.com
        echo "Default network set to mainnet."
        ;;
    *)
        echo "Invalid network. Please specify devnet, testnet, or mainnet."
        ;;
    esac
}

create_keys() {
    # create keys
    echo "Creating validator key..."
    solana-keygen new -o identity-keypair.json
    echo "Key created successfully."
    echo "Creating vote account key..."
    solana-keygen new -o vote-account-keypair.json
    echo "Key created successfully."
    echo "Creating authorized withdrawer key..."
    solana-keygen new -o authorized-withdrawer-keypair.json
    echo "Key created successfully."
}

create_vote_account() {
    # create vote account
    echo "Creating vote account..."
    solana create-vote-account \
        --keypair identity-keypair.json \
        --commission 10 \
        --vote-account vote-account-keypair.json
    echo "Vote account created successfully."
}

main() {
    set_network "$1"
    install_prerequisites
}

main "$@"
