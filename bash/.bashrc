# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.

alias vim=nvim
alias claude="claude --dangerously-skip-permissions"
alias cat='bat --paging=never --style=plain'
alias zed='zeditor'
alias gst='git status'

# Add ~/bin to PATH
export PATH="$HOME/bin:$PATH"

# Setup uv
. "$HOME/.local/bin/env"

# Setup rust (cargo)
. "$HOME/.cargo/env"

# Setup direnv
eval "$(direnv hook bash)"


# add Pulumi to the PATH
export PATH=$PATH:/home/aljohri/.pulumi/bin
