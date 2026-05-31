#!/usr/bin/env bash
set -euo pipefail

# Read-only preview of what stowing WOULD change. For every file tracked in the
# given stow packages, compare it against whatever currently lives at its target
# path under $HOME. Nothing is stowed, adopted, copied, or modified.
#
#   target is a symlink            -> already stowed (skip; nothing would change)
#   target is missing              -> would be newly created (no diff)
#   target is a real file, same    -> identical (skip)
#   target is a real file, differs -> show the diff (yours vs what's on disk)
#
# Diff direction: left/old = YOUR dotfiles, right/new = the file on disk (the
# omarchy/system default). So green = what the on-disk default has beyond yours
# (candidate updates to absorb), red = what yours drops from the default.
#
# Usage: stow-diff.sh [package ...]      (default: the full omarchy stow set)
#        stow-diff.sh hypr waybar        (just those packages)

REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"

# Keep in sync with the Makefile's stow-omarchy set (CORE + claude + DESKTOP + WAYLAND).
DEFAULT_PACKAGES=(
  nvim tmux git fish starship mise delta claude-history claude
  bash zsh scripts alacritty ghostty xdg zed applications code-server
  hypr waybar uwsm omarchy wireplumber elephant imv makima wiremix
)

packages=("$@")
[ ${#packages[@]} -eq 0 ] && packages=("${DEFAULT_PACKAGES[@]}")

# Render a diff of two files. $1 = yours (old), $2 = on-disk (new).
if command -v delta &>/dev/null; then
  show_diff() { delta --paging=never "$1" "$2" || true; }
else
  show_diff() { git --no-pager diff --no-index --color=always -- "$1" "$2" || true; }
fi

differ=()      # "pkg|rel|target|repofile"
created=()     # "pkg|rel"
identical=0
stowed=0
missingpkg=()

for pkg in "${packages[@]}"; do
  if [ ! -d "$pkg" ]; then missingpkg+=("$pkg"); continue; fi
  while IFS= read -r -d '' file; do
    rel="${file#"$pkg"/}"
    target="$HOME/$rel"
    if [ -L "$target" ]; then
      stowed=$((stowed + 1))
    elif [ ! -e "$target" ]; then
      created+=("$pkg|$rel")
    elif cmp -s "$target" "$file"; then
      identical=$((identical + 1))
    else
      differ+=("$pkg|$rel|$target|$file")
    fi
  done < <(find "$pkg" -mindepth 1 \( -type f -o -type l \) -print0)
done

if [ ${#differ[@]} -gt 0 ]; then
  echo "==> ${#differ[@]} file(s) on disk differ from your dotfiles"
  echo "    (left = yours, right = on-disk/omarchy default)"
  echo ""
  for entry in "${differ[@]}"; do
    IFS='|' read -r pkg rel target file <<<"$entry"
    echo "════════════════════════════════════════════════════════════════"
    echo " [$pkg] $rel"
    echo "   on disk: $target"
    echo "════════════════════════════════════════════════════════════════"
    show_diff "$file" "$target"
    echo ""
  done
fi

echo "═══════════════════════════════════════════════════════════════════"
echo "Summary across ${#packages[@]} package(s):"
echo "  differ (real file vs yours): ${#differ[@]}   <- the ones to review"
echo "  would be newly created:      ${#created[@]}"
echo "  already symlinked (stowed):  $stowed"
echo "  identical real files:        $identical"
[ ${#missingpkg[@]} -gt 0 ] && echo "  skipped (no package dir):    ${missingpkg[*]}"
if [ ${#differ[@]} -gt 0 ]; then
  echo ""
  echo "Differing files:"
  for entry in "${differ[@]}"; do
    IFS='|' read -r pkg rel _ _ <<<"$entry"
    echo "  [$pkg] $rel"
  done
fi
