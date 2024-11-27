#!/bin/bash

# Script URL
SCRIPT_URL='https://raw.githubusercontent.com/epignatelli/solange/refs/heads/main/install/build.sh'

# Ensure we are running from a file, not via bash -c
if [[ "$0" == "bash" ]]; then
    temp_script="/tmp/build.sh"
    curl -s "$SCRIPT_URL" -o "$temp_script"
    chmod +x "$temp_script"
    exec "$temp_script" "$@"
fi

create_sol_user() {
    echo "Creating a new user for Solana..."
    if ! id sol &>/dev/null; then
        sudo adduser sol
        sudo usermod -aG sudo sol
        echo "User 'sol' created successfully."
    else
        echo "User 'sol' already exists."
    fi

    # Re-run the script as the sol user
    if [[ "$(whoami)" != "sol" ]]; then
        exec sudo -u sol "$0" "$@"
    fi
}

main() {
    create_sol_user
    echo "Running the rest of the script as $(whoami)..."
}

main "$@"
