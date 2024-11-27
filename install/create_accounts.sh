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

install_prerequisites() {
    # Install prerequisites
    echo "Installing Solana..."
    sol_version=$(cat SOL_VERSION.txt || echo "stable")
    sh -c "$(curl -sSfL https://release.anza.xyz/$sol_version/install)"
    # Append to PATH
    append_to_path "$HOME/.local/share/solana/install/active_release/bin"
    echo "Solana installed successfully."
}

set_network() {
    # Set network to devnet, testnet, or mainnet
    echo "Setting default network..."
    # Use testnet by default
    network=${1:-"testnet"}

    case $network in
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
        echo "Invalid network $network. Please specify devnet, testnet, or mainnet."
        exit 1
        ;;
    esac
}

create_keys() {
    # make sure output folder exists
    mkdir -p ./keys

    # Create keys
    echo "Creating validator key..."
    solana-keygen new -o ./keys/identity-keypair.json
    echo "Key created successfully."
    echo "Creating vote account key..."
    solana-keygen new -o ./keys/vote-account-keypair.json
    echo "Key created successfully."
    echo "Creating authorized withdrawer key..."
    solana-keygen new -o ./keys/authorized-withdrawer-keypair.json
    echo "Key created successfully."
}

#!/bin/bash

airdrop_sol() {
    local amount=$1
    local keypair=$2
    local max_retries=${3:-10} # Maximum retries (default: 10)
    local delay=${4:-5}        # Delay between retries in seconds (default: 5)
    local attempt=1

    echo "Attempting to airdrop $amount SOL to $keypair..."

    while ((attempt <= max_retries)); do
        if solana airdrop "$amount" "$keypair" -k $keypair; then
            echo "Airdrop successful on attempt $attempt."
            return 0
        else
            echo "Airdrop failed on attempt $attempt. Retrying in $delay seconds..."
            sleep "$delay"
            ((attempt++))
        fi
    done

    echo "Airdrop failed after $max_retries attempts."
    return 1
}

create_vote_account() {
    # airdrop some sol if on testnet or devnet
    echo "Airdropping SOL..."
    if [[ $(solana config get json_rpc_url | grep -o "testnet") == "testnet" || $(solana config get json_rpc_url | grep -o "devnet") == "devnet" ]]; then
        echo "testnet or devnet detected, airdropping 1 SOL..."
        airdrop_sol 1 ./keys/identity-keypair.json
        echo "Airdrop complete. Current balance is"
        solana balance ./keys/identity-keypair.json
    fi

    # Create vote account
    echo "Creating vote account..."
    solana create-vote-account \
        --fee-payer ./keys/identity-keypair.json \
        ./keys/vote-account-keypair.json \
        ./keys/identity-keypair.json \
        ./keys/authorized-withdrawer-keypair.json

    echo "Vote account created successfully."
}

print_usage() {
    echo "Usage: $0 [--network <devnet|testnet|mainnet>] [--skip-prereqs] [--skip-keys] [--skip-vote]"
}

main() {
    local network="testnet"
    local skip_prereqs=false
    local skip_keys=false
    local skip_vote=false

    # Parse named arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        --network)
            network="$2"
            shift 2
            ;;
        --skip-prereqs)
            skip_prereqs=true
            shift
            ;;
        --skip-keys)
            skip_keys=true
            shift
            ;;
        --skip-vote)
            skip_vote=true
            shift
            ;;
        -h | --help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
        esac
    done

    # Execute steps based on arguments
    if ! $skip_prereqs; then
        install_prerequisites
    fi

    set_network "$network"

    if ! $skip_keys; then
        create_keys
    fi

    if ! $skip_vote; then
        create_vote_account
    fi
}

main "$@"
