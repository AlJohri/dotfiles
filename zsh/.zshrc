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

# Add ~/bin and ~/.local/bin to PATH
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Setup cargo/rust
if [[ -f "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi

# Setup mise
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# Setup direnv
if command -v direnv &> /dev/null; then
  eval "$(direnv hook zsh)"
fi

# Setup starship
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# AWS CLI completion
# https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-completion.html#cli-command-completion-enable
if command -v aws_completer &> /dev/null; then
  autoload bashcompinit && bashcompinit
  autoload -Uz compinit && compinit
  complete -C 'aws_completer' aws
fi

# zsh-syntax-highlighting must be last line
# https://github.com/zsh-users/zsh-syntax-highlighting?tab=readme-ov-file#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file
if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  . /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
