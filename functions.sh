# Custom Functions

make_ssh_key() {
  if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    EMAIL=$(git config user.email)
    if [ -z $EMAIL ]; then
      echo "Email is not yet set in git config. Run: git config --global user.email <EMAIL>."
      return 1
    fi
    ssh-keygen -q -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" -C "$EMAIL"
    eval "$(ssh-agent -s)"
    ssh-add -K "$HOME/.ssh/id_rsa"
    # linux uses: ssh-add "$HOME/.ssh/id_rsa"
    pbcopy < "$HOME/.ssh/id_rsa.pub"
    open https://github.com/settings/ssh
  else
    echo "ssh key already exists"
  fi
}

function startgpg() {
  # https://wincent.com/wiki/Using_gpg-agent_on_OS_X
  # https://blog.chendry.org/2015/03/13/starting-gpg-agent-in-osx.html
  export GPG_TTY=$(tty)
  [ -f "$HOME/.gpg-agent-info" ] && source "$HOME/.gpg-agent-info"
  if [ -S "${GPG_AGENT_INFO%%:*}" ]; then
    [ "$debug_dotfiles" = true ] && echo "gpg-agent already started."
    export GPG_AGENT_INFO
  else
    [ "$debug_dotfiles" = true ] && echo "starting new gpg-agent"
    eval $(gpg-agent --allow-preset-passphrase --use-standard-socket --daemon --write-env-file "$HOME/.gpg-agent-info")
  fi

  if [ "$debug_dotfiles" = true ]; then
    USER_EMAIL="$(git config --global --get user.email)"
    KEYGRIP=$(gpg --fingerprint --fingerprint $USER_EMAIL | grep fingerprint | tail -1 | cut -d= -f2 | sed -e 's/ //g')
    echo "GPG_TTY=$GPG_TTY"
    echo "GPG_AGENT_INFO=$GPG_AGENT_INFO"
    echo "KEYGRIP=$KEYGRIP"
  fi
}

# Schedule sleep in X minutes, use like: sleep-in 60
function sleepin() {
  local minutes=$1
  local datetime=`date -v+${minutes}M +"%m/%d/%y %H:%M:%S"`
  sudo pmset schedule sleep "$datetime"
}

function sourceenv() {
  export $(grep -v '^#' .env | xargs)
}

background() {
    nohup bash --login -c "$*" &
}

background-log() {
    filename="$1"
    shift
    nohup bash --login -c "$*" &> "$filename" &
}

