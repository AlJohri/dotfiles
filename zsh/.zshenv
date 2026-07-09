# .zshenv is the only startup file zsh sources for NON-login, NON-interactive
# shells -- e.g. `ssh host <cmd>`, which runs `zsh -c <cmd>`. Homebrew's shellenv
# normally lives in .zprofile (login-only), so remote commands run without brew on
# PATH. Putting it here too makes brew available to those shells.
#
# Guarded on the Apple Silicon brew path, so this is a no-op on Linux (no Homebrew)
# and stays idempotent alongside .zprofile (modern `brew shellenv` skips dup PATH
# entries).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
