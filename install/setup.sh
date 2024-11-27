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
        sudo chmod -a+x $SCRIPT_DIR/build.sh
        exec sudo -u sol $SCRIPT_DIR/build.sh "$@"
    fi
}

main() {
    create_sol_user
    echo "Running the rest of the script as $(whoami)..."
}

main "$@"
