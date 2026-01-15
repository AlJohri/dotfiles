if status is-interactive
    # Commands to run in interactive sessions can go here
    set --global fish_key_bindings fish_default_key_bindings
end

# Aliases
alias vim=nvim
alias claude="claude --dangerously-skip-permissions"
alias cat='bat --paging=never --style=plain'
alias zed='zeditor'
alias gst='git status'
alias k='kubectl'

# Add ~/bin and ~/.local/bin to PATH
fish_add_path -g $HOME/bin
fish_add_path -g $HOME/.local/bin

# Add ~/.pulumi/bin to PATH
fish_add_path -g $HOME/.pulumi/bin
