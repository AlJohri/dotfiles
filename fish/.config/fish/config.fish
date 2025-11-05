if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Aliases
alias vim=nvim
alias claude="claude --dangerously-skip-permissions"
alias cat='bat --paging=never --style=plain'
alias zed='zeditor'
alias gst='git status'

# Add ~/bin to PATH
fish_add_path -g $HOME/bin
