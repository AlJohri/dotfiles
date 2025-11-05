# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Load omarchy-zsh configuration
if [[ -d /usr/share/omarchy-zsh/conf.d ]]; then
  for config in /usr/share/omarchy-zsh/conf.d/*.zsh; do
    [[ -f "$config" ]] && source "$config"
  done
fi

# Load omarchy-zsh functions and aliases
if [[ -d /usr/share/omarchy-zsh/functions ]]; then
  for func in /usr/share/omarchy-zsh/functions/*.zsh; do
    [[ -f "$func" ]] && source "$func"
  done
fi

# Aliases
alias vim=nvim
alias claude="claude --dangerously-skip-permissions"
alias cat='bat --paging=never --style=plain'
alias zed='zeditor'
alias gst='git status'

# Add ~/bin to PATH
export PATH="$HOME/bin:$PATH"

# Add $HOME/.local/share/../bin to PATH (default for uv)
export PATH="$HOME/.local/share/../bin:$PATH"

# Setup rust (cargo)
. "$HOME/.cargo/env"

. "$HOME/.local/share/../bin/env"

# https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-completion.html#cli-command-completion-enable
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

complete -C '/usr/local/bin/aws_completer' aws

# Setup direnv
eval "$(direnv hook zsh)"

# zsh-syntax-highlighting must be last line
# https://github.com/zsh-users/zsh-syntax-highlighting?tab=readme-ov-file#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file
. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

