#!/bin/bash
set -euo pipefail

# Function to display usage
usage() {
    echo "Usage: $0 --remote-host <hostname> [--validator-keypair <path>] [--vote-keypair <path>] [--output-dir <path>]"
    echo
    echo "Arguments:"
    echo "  --remote-host        Remote hostname or IP address (required)."
    echo "  --validator-keypair  Path to the validator keypair file (default: \$HOME/solange/validator-keypair.json)."
    echo "  --vote-keypair       Path to the vote account keypair file (default: \$HOME/solange/vote-account-keypair.json)."
    echo "  --output-dir         Output directory for public key files (default: \$HOME/solange)."
    exit 1
}

# Default values
REMOTE_HOST=""
VALIDATOR_KEYPAIR="$HOME/solange/keys/validator-keypair.json"
VOTE_KEYPAIR="$HOME/solange/keys/vote-account-keypair.json"
OUTPUT_DIR="$HOME/solange/keys"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --remote-host)
            REMOTE_HOST="$2"
            shift 2
            ;;
        --validator-keypair)
            VALIDATOR_KEYPAIR="$2"
            shift 2
            ;;
        --vote-keypair)
            VOTE_KEYPAIR="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check required arguments
if [[ -z "$REMOTE_HOST" ]]; then
    echo "Error: --remote-host is required."
    usage
fi

# Validate input files
if [[ ! -f "$VALIDATOR_KEYPAIR" ]]; then
    echo "Error: Validator keypair file '$VALIDATOR_KEYPAIR' does not exist."
    exit 1
fi

if [[ ! -f "$VOTE_KEYPAIR" ]]; then
    echo "Error: Vote keypair file '$VOTE_KEYPAIR' does not exist."
    exit 1
fi

# Generate public keys
echo "Generating public keys..."
VALIDATOR_PUBKEY=$(solana-keygen pubkey "$VALIDATOR_KEYPAIR")
VOTE_PUBKEY=$(solana-keygen pubkey "$VOTE_KEYPAIR")

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Write public keys to files
echo "$VALIDATOR_PUBKEY" >"$OUTPUT_DIR/validator.pub"
echo "$VOTE_PUBKEY" >"$OUTPUT_DIR/vote.pub"
echo "Public keys written to $OUTPUT_DIR."

# Transfer files to remote host
echo "Transferring files to $REMOTE_HOST..."
scp "$OUTPUT_DIR/validator.pub" "sol@$REMOTE_HOST:/home/sol/solange/validator.json"
scp "$OUTPUT_DIR/vote.pub" "sol@$REMOTE_HOST:/home/sol/solange/vote.json"
echo "Files successfully transferred to $REMOTE_HOST."
