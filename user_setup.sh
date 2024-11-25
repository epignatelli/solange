#!/bin/bash
# Script to set up a development environment
# Installs required packages, configures Git, and sets up Oh-My-Zsh with plugins and a custom theme.

# Exit on errors
set -euo pipefail

# Function to update and upgrade the system
update_system() {
    echo "Updating and upgrading system packages..."
    sudo apt update -y
    sudo apt upgrade -y
    echo "System packages updated."
}

# Function to install required packages
install_packages() {
    echo "Installing required packages..."
    sudo apt install -y git wget zsh
    echo "Required packages installed."
}

# Function to configure Git
configure_git() {
    echo "Configuring Git..."
    git config --global credential.helper store
    echo "Git configuration complete."
}

# Function to install Oh-My-Zsh
install_oh_my_zsh() {
    echo "Installing Oh-My-Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" --unattended
    else
        echo "Oh-My-Zsh is already installed."
    fi
}

# Function to set Oh-My-Zsh plugins and theme
configure_oh_my_zsh() {
    echo "Configuring Oh-My-Zsh plugins and theme..."
    
    # Clone plugins if not already cloned
    PLUGIN_DIR="$HOME/.oh-my-zsh/plugins"
    mkdir -p "$PLUGIN_DIR"
    
    if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
    fi

    if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
    fi

    # Update ~/.zshrc for plugins and theme
    ZSHRC_FILE="$HOME/.zshrc"
    sed -i "s/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/" "$ZSHRC_FILE"
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"af-magic\"/" "$ZSHRC_FILE"

    echo "Oh-My-Zsh plugins and theme configured."
}

# Main script execution
main() {
    # Update and upgrade the system
    update_system

    # Install required packages
    install_packages

    # Configure Git
    configure_git

    # Install and configure Oh-My-Zsh
    install_oh_my_zsh
    configure_oh_my_zsh

    echo "Development environment setup complete. Please restart your terminal or run 'exec zsh' to apply changes."
}

# Run the main function
main "$@"
