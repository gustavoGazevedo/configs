#!/bin/bash

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# List of packages to install
packages=(
    fzf
    fd
    nvim
    ripgrep
    lazygit
    lazydocker
    zoxide
    thefuck
    bat
    eza
    tlrc
    navi
    neofetch
)

# Install each package using Homebrew
for pkg in "${packages[@]}"; do
    if brew list -1 | grep -q "^${pkg}\$"; then
        echo "${pkg} is already installed."
    else
        echo "Installing ${pkg}..."
        brew install "${pkg}"
    fi
done

echo "All packages installed."

