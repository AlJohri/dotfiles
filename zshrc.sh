# Adapted from https://github.com/MikeMcQuaid/dotfiles/blob/master/zshrc.sh

# load shared shell configuration
source ~/.zprofile
source ~/.shrc

# History file
export HISTFILE=~/.zsh_history

# Don't show duplicate history entires
setopt hist_find_no_dups

# Remove unnecessary blanks from history
setopt hist_reduce_blanks

# Share history between instances
setopt share_history

# Don't hang up background jobs
setopt no_hup

# Commands that start with a space are not put in history
setopt histignorespace

source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/local/share/zsh/site-functions/_aws

