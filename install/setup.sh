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
        SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

        echo "Re-running the script as the 'sol' user..."
        chown -R sol:sol "$SCRIPT_DIR"
        sudo -u sol bash "$SCRIPT_DIR/build.sh"
        exit
    fi
}

main() {
    create_sol_user
    echo "Running the rest of the script as $(whoami)..."
}

main "$@"
