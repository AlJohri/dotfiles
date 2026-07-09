#!/usr/bin/env bash
set -euo pipefail

# Stow the dotfiles. Two modes, chosen by whether stdin is a terminal:
#
#   Interactive (a TTY -- a human doing a fresh install or reconciling after an
#   `omarchy upgrade`): stow with --adopt, which pulls any pre-existing real file
#   at a target path INTO the repo so the symlink can be created -- meaning the
#   system's defaults temporarily overwrite our tracked files. Then review every
#   file that drifted from our tracked version. Files unique to us (or identical
#   to the system's) never show up; only genuine drift does. For each you choose:
#     [k] keep mine   -> git checkout (restore our version; symlink points to it)
#     [t] take theirs -> git add (absorb the system version; commit later)
#     [s] skip        -> leave it modified in the working tree to decide later
#
#   Non-interactive (no TTY -- an automated/idempotent re-run, e.g. a setup script
#   invoked without a terminal): safe `--restow` only. Re-creates symlinks, never
#   adopts, and FAILS LOUDLY on a real-file conflict instead of silently absorbing
#   drift or hanging on a prompt no one can answer.
#
# Usage: stow-review.sh [make-target]   (default: stow-omarchy)

REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"

STOW_TARGET="${1:-stow-omarchy}"

# Non-interactive: no one can answer the per-file review, so just re-assert the
# symlinks safely. --restow fails loudly on a real-file conflict (drift) rather
# than adopting it, so automated re-runs never silently pollute the repo.
if [ ! -t 0 ]; then
    echo "==> Stowing ($STOW_TARGET, --restow, non-interactive)..."
    make STOW_FLAGS=--restow "$STOW_TARGET"
    exit 0
fi

# Interactive from here: --adopt + review. We use `git checkout`/`git add` to
# resolve each file, which would clobber unrelated uncommitted work -- require a
# clean tree first.
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "ERROR: working tree has uncommitted changes." >&2
    echo "  stow-review uses 'git checkout' to restore files and would discard them." >&2
    echo "  Commit or stash first, then re-run." >&2
    exit 1
fi

echo "==> Stowing ($STOW_TARGET, with --adopt)..."
make STOW_FLAGS=--adopt "$STOW_TARGET"

# Anything git now reports as modified is a collision whose on-disk content
# differs from ours (identical adopts leave no diff and never appear).
mapfile -t changed < <(git diff --name-only)

if [ ${#changed[@]} -eq 0 ]; then
    echo "==> No incoming changes -- your dotfiles match what was already on disk."
    exit 0
fi

echo ""
echo "==> ${#changed[@]} file(s) on disk differ from your dotfiles:"
git --no-pager diff --stat
echo ""

show_diff() {
    if command -v delta &>/dev/null; then
        git --no-pager diff -- "$1" | delta --paging=never
    else
        git --no-pager diff --color=always -- "$1"
    fi
}

absorbed=()
skipped=()
for f in "${changed[@]}"; do
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo " $f"
    echo "────────────────────────────────────────────────────────────────"
    show_diff "$f"
    echo ""
    while true; do
        read -rp "  [k] keep mine (default)   [t] take theirs   [s] skip: " ans </dev/tty
        case "${ans:-k}" in
            k|K|"") git checkout -- "$f"; echo "    kept yours."; break ;;
            t|T)    git add -- "$f"; absorbed+=("$f"); echo "    took theirs (staged)."; break ;;
            s|S)    skipped+=("$f"); echo "    skipped (left modified in working tree)."; break ;;
            *)      echo "    please answer k, t, or s." ;;
        esac
    done
done

echo ""
if [ ${#absorbed[@]} -gt 0 ]; then
    echo "==> Absorbed ${#absorbed[@]} file(s) from the system (staged for commit):"
    printf '      %s\n' "${absorbed[@]}"
    echo "    Review with 'git diff --staged' and commit when ready."
fi
if [ ${#skipped[@]} -gt 0 ]; then
    echo "==> Left ${#skipped[@]} file(s) modified to decide later:"
    printf '      %s\n' "${skipped[@]}"
fi
if [ ${#absorbed[@]} -eq 0 ] && [ ${#skipped[@]} -eq 0 ]; then
    echo "==> Kept all your dotfiles versions. Nothing absorbed."
fi
