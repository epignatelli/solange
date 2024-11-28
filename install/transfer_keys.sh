#!/bin/bash
set -eo pipefail

# Function to display usage
usage() {
    echo "Usage: $0 --remote-host <hostname> [--validator-keypair <path>] [--vote-keypair <path>] [--output-dir <path>]"
    echo
    echo "Arguments:"
    echo "  --port               Port number to use for SSH connection (default: 22)."
    echo "  --remote-host        Remote hostname or IP address (required)."
    echo "  --validator-keypair  Path to the validator keypair file (default: \$HOME/solange/keys/validator-keypair.json)."
    echo "  --vote-keypair       Path to the vote account keypair file (default: \$HOME/solange/keys/vote-account-keypair.json)."
    exit 1
}

# Default values
SCRIPT_DIR=$(dirname $(readlink -f $0))
PORT="22"
REMOTE_HOST=""
VALIDATOR_KEYPAIR="$SCRIPT_DIR/../keys/validator-keypair.json"
VOTE_KEYPAIR="$SCRIPT_DIR/../keys/vote-account-keypair.json"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --port)
        PORT="$2"
        shift 2
        ;;
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
    -h | --help)
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

# Transfer files to remote host
echo "Transferring files to $REMOTE_HOST..."
DESTINATION_FOLDER="/home/sol/solange/keys"
ssh sol@$REMOTE_HOST -p $PORT "mkdir -p $DESTINATION_FOLDER"
scp -P $PORT "$VALIDATOR_KEYPAIR" "$VOTE_KEYPAIR" "sol@$REMOTE_HOST:$DESTINATION_FOLDER/"
echo "Files successfully transferred to $REMOTE_HOST."
