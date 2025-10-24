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

# Get the dotfiles repo root early to validate path is not inside it
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

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

# Stow the package
echo "Stowing package: $PACKAGE_NAME"
stow "$PACKAGE_NAME"

# Update Makefile to add the package to the 'all' target if not already present
MAKEFILE="$REPO_ROOT/Makefile"
if [ -f "$MAKEFILE" ]; then
    # Check if package is already in the Makefile
    if ! grep -q "stow.*$PACKAGE_NAME" "$MAKEFILE"; then
        echo "Adding $PACKAGE_NAME to Makefile"
        # Use sed to add the package to the stow command line
        sed -i "s/\(stow.*\)/\1 $PACKAGE_NAME/" "$MAKEFILE"
    else
        echo "$PACKAGE_NAME already in Makefile"
    fi
fi

echo "✓ Successfully adopted $TARGET_PATH"
echo "✓ Package '$PACKAGE_NAME' is now managed by stow"
echo "✓ Makefile updated"
