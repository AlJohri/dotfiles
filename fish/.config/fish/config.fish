if status is-interactive
    # Commands to run in interactive sessions can go here
    set --global fish_key_bindings fish_default_key_bindings
end

# Aliases
alias vim=nvim
alias happy="happy --yolo"
# On Linux the Zed CLI is `zeditor` (the package name); on macOS it's `zed`.
if type -q zeditor; and not type -q zed
    alias zed='zeditor'
end
alias gst='git_status_or_worktrees'
alias k='kubectl'


# Add ~/.pulumi/bin to PATH
fish_add_path -g $HOME/.pulumi/bin
