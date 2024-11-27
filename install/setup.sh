#!/bin/bash

create_sol_user() {
    if ! id sol &>/dev/null; then
        echo "Creating a new user for Solana..."
        sudo adduser sol
        sudo usermod -aG sudo sol
        echo "User 'sol' created successfully."
    else
        echo "User 'sol' already exists."
    fi

    # Re-run the script as the sol user
    if [[ "$(whoami)" != "sol" ]]; then
        SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
        SCRIPT_PATH="$SCRIPT_DIR/$(basename -- "${BASH_SOURCE[0]}")"

        echo "Re-running the script as the 'sol' user..."
        sudo -u sol bash "$SCRIPT_PATH"
        exit
    fi
}

main() {
    create_sol_user
    echo "Running the rest of the script as $(whoami)..."
}

main "$@"
