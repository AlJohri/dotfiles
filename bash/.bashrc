# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

alias vim=nvim
alias claude="claude --dangerously-skip-permissions"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
alias gst='git status'

# Add ~/bin to PATH
export PATH="$HOME/bin:$PATH"

. "$HOME/.cargo/env"
