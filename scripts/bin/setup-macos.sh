#!/usr/bin/env bash
set -euo pipefail

# Setup script for macOS

# macOS doesn't have readlink -f, use Python instead
REAL_SCRIPT="$(python3 -c "import os; print(os.path.realpath('${BASH_SOURCE[0]}'))")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"

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
brew install --cask 1password-cli
brew install gh

echo "==> Installing mise..."
if [ ! -f "$HOME/.local/bin/mise" ]; then
    curl https://mise.run | sh
fi

echo "==> Initializing git submodules..."
git submodule update --init

if ! gh auth token &>/dev/null; then
    echo "==> Logging into GitHub (mise installs binaries from GitHub in bulk and will get 403 rate-limited without a token)..."
    gh auth login
fi

echo "==> Installing mise tools..."
mise trust "$DOTFILES_DIR/mise/.config/mise/config.toml"
GITHUB_TOKEN="$(gh auth token)" mise install -C "$DOTFILES_DIR/mise/.config/mise"
eval "$(mise env -s bash --cd "$DOTFILES_DIR/mise/.config/mise")"

if ! command -v claude &> /dev/null && [[ ! -x "$HOME/.claude/local/bin/claude" ]]; then
    echo "==> Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

echo "==> Installing Claude Code MCP servers..."
"$DOTFILES_DIR/scripts/bin/setup-claude-code-mcp-servers.sh"

echo "==> Installing WhichSpace..."
if [ ! -d "/Applications/WhichSpace.app" ]; then
    brew install --cask gechr/tap/whichspace
    xattr -r -d com.apple.quarantine /Applications/WhichSpace.app
fi

echo "==> Adding WhichSpace to Login Items..."
osascript <<'EOF'
tell application "System Events"
    if not (exists login item "WhichSpace") then
        make login item at end with properties {path:"/Applications/WhichSpace.app", hidden:true}
    end if
end tell
EOF

echo "==> Installing skhd..."
if ! command -v skhd &> /dev/null; then
    brew install koekeishiya/formulae/skhd
fi

echo "==> Installing yabai..."
if ! command -v yabai &> /dev/null; then
    curl -L https://raw.githubusercontent.com/asmvik/yabai/master/scripts/install.sh | sh /dev/stdin
fi

echo "==> Stowing dotfiles..."
make stow-macos

# --adopt pulls existing files into the repo, which on a fresh install means
# system defaults overwrite our tracked files. Show what changed and let
# the user decide whether to restore their versions.
if ! git diff --quiet; then
    echo ""
    echo "==> stow --adopt imported the following changes from system defaults:"
    echo "    (These are files in ~ that differed from your dotfiles.)"
    echo ""
    git --no-pager diff --stat
    echo ""
    git --no-pager diff
    echo ""
    read -rp "==> Restore your dotfiles versions? (Y/n) " answer
    if [[ "${answer:-Y}" =~ ^[Yy]$ ]]; then
        git checkout .
        echo "==> Restored dotfiles to your tracked versions."
    else
        echo "==> Keeping adopted changes."
    fi
fi

echo "==> Configuring macOS defaults..."
defaults write -g NSWindowShouldDragOnGesture -bool true
defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10
# Don't jump to another Space when activating an app that already has windows
# elsewhere — keeps `cmd+enter`-launched Ghostty windows on the current space.
# AppleSpacesSwitchOnActivate alone is ignored by AppleScript `activate`; the
# Dock's workspaces-auto-swoosh is the actual toggle, and Dock must restart.
defaults write -g AppleSpacesSwitchOnActivate -bool false
defaults write com.apple.dock workspaces-auto-swoosh -bool NO
killall Dock 2>/dev/null || true

# Save screenshots to ~/Pictures instead of ~/Desktop. macOS TCC protects
# Desktop, which blocks Claude Code (and other CLI tools) from reading
# screenshot files even with Full Disk Access granted —
# https://github.com/anthropics/claude-code/issues/51312. Pictures is not
# TCC-protected so files there are readable.
mkdir -p "$HOME/Pictures"
defaults write com.apple.screencapture location -string "$HOME/Pictures"
killall SystemUIServer 2>/dev/null || true

# Rebind screenshot shortcuts off cmd+shift+{3,4,5} so skhd can use those for
# space switching (matches the omarchy keymap). New bindings: cmd+ctrl+{3,4,5}.
# IDs: 28=screen→file, 30=area→file, 184=screenshot UI.
# Modifier mask cmd+ctrl = 0x100000 | 0x040000 = 1310720.
# Param tuple is (unicode_char, keycode, modifier_mask); keycodes 3=20, 4=21, 5=23.
# NOTE: must use PlistBuddy (not `defaults write -dict-add` with a literal
# plist string) — the literal-string form writes everything as CFString, and
# the WindowServer silently ignores entries whose enabled/parameters aren't
# proper integers, so the rebind appears in `defaults read` but never takes
# effect.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
hotkeys_plist="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
for entry in "28 51 20" "30 52 21" "184 53 23"; do
    set -- $entry
    id=$1; char=$2; code=$3
    /usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:${id}" "$hotkeys_plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy \
        -c "Add :AppleSymbolicHotKeys:${id} dict" \
        -c "Add :AppleSymbolicHotKeys:${id}:enabled bool true" \
        -c "Add :AppleSymbolicHotKeys:${id}:value dict" \
        -c "Add :AppleSymbolicHotKeys:${id}:value:type string standard" \
        -c "Add :AppleSymbolicHotKeys:${id}:value:parameters array" \
        -c "Add :AppleSymbolicHotKeys:${id}:value:parameters: integer ${char}" \
        -c "Add :AppleSymbolicHotKeys:${id}:value:parameters: integer ${code}" \
        -c "Add :AppleSymbolicHotKeys:${id}:value:parameters: integer 1310720" \
        "$hotkeys_plist"
done
killall cfprefsd 2>/dev/null || true
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
echo "    (If shortcuts still don't fire, log out and back in — Sequoia's"
echo "     WindowServer caches the binding table at session start.)"

echo "==> Configuring yabai scripting addition (requires SIP disabled)..."
echo "    If you haven't disabled SIP yet, reboot into Recovery Mode (hold Power),"
echo "    open Terminal, run: csrutil disable"
echo "    then reboot and re-run this script."
echo ""
yabai_sudoers_line="$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa"
yabai_sudoers_marker="$HOME/.cache/setup-macos/yabai-sudoers.sha256"
yabai_sudoers_hash=$(echo "$yabai_sudoers_line" | shasum -a 256 | cut -d " " -f 1)
if [ -f "$yabai_sudoers_marker" ] && [ "$(cat "$yabai_sudoers_marker")" = "$yabai_sudoers_hash" ]; then
    echo "    yabai sudoers entry already up to date, skipping."
else
    echo "$yabai_sudoers_line" | sudo tee /private/etc/sudoers.d/yabai
    mkdir -p "$(dirname "$yabai_sudoers_marker")"
    echo "$yabai_sudoers_hash" > "$yabai_sudoers_marker"
fi

echo "==> Starting services..."
skhd --start-service
yabai --start-service

echo "==> Done! Restart your shell or run: exec fish"
