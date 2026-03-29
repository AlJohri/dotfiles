#!/usr/bin/env bash
set -euo pipefail

# Merges claude-json-overrides.json into ~/.claude.json.
# Idempotent: re-running overwrites only the keys in the overrides file.

REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
OVERRIDES="$DOTFILES_DIR/claude/.claude/claude-json-overrides.json"
CLAUDE_JSON="$HOME/.claude.json"

if [ ! -f "$OVERRIDES" ]; then
    echo "ERROR: overrides file not found: $OVERRIDES" >&2
    exit 1
fi

command -v jq &>/dev/null || { echo "ERROR: jq is required" >&2; exit 1; }

if [ ! -f "$CLAUDE_JSON" ]; then
    echo '{}' > "$CLAUDE_JSON"
fi

echo "==> Applying Claude Code settings from claude-json-overrides.json..."

changes=$(jq -r --slurpfile overrides "$OVERRIDES" '
  . as $current |
  $overrides[0] | to_entries[] |
  .key as $k | .value as $v |
  if $current[$k] == $v then empty
  elif $current | has($k) then
    "    \($k): \($current[$k]) -> \($v)"
  else
    "    \($k): (unset) -> \($v)"
  end
' "$CLAUDE_JSON")

if [ -n "$changes" ]; then
    tmp=$(mktemp)
    jq -s '.[0] * .[1]' "$CLAUDE_JSON" "$OVERRIDES" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
    echo "$changes"
else
    echo "    All settings already up to date."
fi

echo "==> Trusting home directory workspace..."

trusted=$(jq -r '.projects["/home/aljohri"].hasTrustDialogAccepted // false' "$CLAUDE_JSON")
if [ "$trusted" = "true" ]; then
    echo "    Already trusted."
else
    tmp=$(mktemp)
    jq '.projects["/home/aljohri"].hasTrustDialogAccepted = true' "$CLAUDE_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
    echo "    /home/aljohri: false -> true"
fi

echo "==> Done."
