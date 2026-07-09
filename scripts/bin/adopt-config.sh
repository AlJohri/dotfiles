#!/usr/bin/env bash

set -e

# Usage: ./scripts/adopt-config.sh <path>
# Example: ./scripts/adopt-config.sh ~/.config/hyprmon

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path>"
    echo "Example: $0 ~/.config/hyprmon"
    exit 1
fi

# Get the target path and expand ~
TARGET_PATH="${1/#\~/$HOME}"

if [ ! -e "$TARGET_PATH" ]; then
    echo "Error: Path does not exist: $TARGET_PATH"
    exit 1
fi

# Get absolute path
TARGET_PATH=$(readlink -f "$TARGET_PATH")

# Derive the repo root from this script's location (scripts/bin/adopt-config.sh)
# rather than hardcoding ~/dotfiles.
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
REPO_ROOT="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"

# Validate that the target path is not inside the dotfiles repo
if [[ "$TARGET_PATH" == "$REPO_ROOT"* ]]; then
    echo "Error: Path is inside the dotfiles repo. Please provide a path from your home directory (e.g., ~/.config/starship.toml)"
    exit 1
fi

# Determine the relative path from $HOME
if [[ "$TARGET_PATH" == "$HOME"/* ]]; then
    REL_PATH="${TARGET_PATH#$HOME/}"
else
    echo "Error: Path must be under $HOME"
    exit 1
fi

# Extract package name from the path
# For ~/.config/hyprmon -> package is "hyprmon"
# For ~/.config/starship.toml -> package is "starship"
# For ~/bin/something -> package is "bin"
if [[ "$REL_PATH" == .config/* ]]; then
    PACKAGE_NAME=$(echo "$REL_PATH" | cut -d'/' -f2)
    # Strip file extension if present (e.g., starship.toml -> starship)
    PACKAGE_NAME="${PACKAGE_NAME%.*}"
elif [[ "$REL_PATH" == bin/* ]]; then
    PACKAGE_NAME="bin"
else
    # For other paths, use the first directory component
    PACKAGE_NAME=$(echo "$REL_PATH" | cut -d'/' -f1)
    # Strip file extension if present
    PACKAGE_NAME="${PACKAGE_NAME%.*}"
fi

# Change to dotfiles repo root
cd "$REPO_ROOT"

echo "Adopting $TARGET_PATH into package '$PACKAGE_NAME'"

# Create package directory structure
PACKAGE_DIR="$REPO_ROOT/$PACKAGE_NAME"
TARGET_DIR="$PACKAGE_DIR/$REL_PATH"

mkdir -p "$(dirname "$TARGET_DIR")"

# Copy the files into the package
echo "Copying files from $TARGET_PATH to $TARGET_DIR"
cp -r "$TARGET_PATH" "$(dirname "$TARGET_DIR")/"

# Remove the original directory/file
echo "Removing original: $TARGET_PATH"
rm -rf "$TARGET_PATH"

# Stow the package. The original was just removed, so the target path is free --
# a plain stow creates the symlinks (no --adopt needed).
echo "Stowing package: $PACKAGE_NAME"
stow -t ~ "$PACKAGE_NAME"

# The Makefile groups packages into CORE / DESKTOP / WAYLAND / MACOS variables (not
# on the stow lines), and which tier a new package belongs to is a judgment call.
# Rather than guess-edit the Makefile, report whether it's already listed and, if
# not, point at exactly where to add it.
MAKEFILE="$REPO_ROOT/Makefile"
echo ""
if grep -qE "^(CORE|DESKTOP|WAYLAND|MACOS) =.*\\b$PACKAGE_NAME\\b" "$MAKEFILE"; then
    echo "✓ '$PACKAGE_NAME' is already listed in a Makefile package group."
else
    echo "NEXT STEP: add '$PACKAGE_NAME' to the right package group in $MAKEFILE:"
    grep -nE "^(CORE|DESKTOP|MACOS|WAYLAND) =" "$MAKEFILE" | sed 's/^/    /'
    echo "    (CORE = portable/core, DESKTOP = +desktop, WAYLAND = +wayland, MACOS = +macos)"
fi

echo ""
echo "✓ Successfully adopted $TARGET_PATH"
echo "✓ Package '$PACKAGE_NAME' is now managed by stow"
