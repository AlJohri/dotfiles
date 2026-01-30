#!/usr/bin/env bash
set -euo pipefail

# Setup script for macOS

echo "==> Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "==> Installing system packages..."
brew install \
    stow \
    make \
    git \
    fish

echo "==> Installing mise..."
if ! command -v mise &> /dev/null; then
    curl https://mise.jdx.dev/install.sh | sh
fi

echo "==> Installing mise tools..."
mise install

echo "==> Initializing git submodules..."
# macOS doesn't have readlink -f, use Python instead
REAL_SCRIPT="$(python3 -c "import os; print(os.path.realpath('${BASH_SOURCE[0]}'))")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

echo "==> Stowing dotfiles..."
make stow-portable

echo "==> Done! Restart your shell or run: exec fish"
