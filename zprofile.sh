# 077 would be more secure, but 022 is more useful.
umask 022

# Save more history
export HISTSIZE=100000
export SAVEHIST=100000
export HOMEBREW_PREFIX="/usr/local"

# OS variables
[ $(uname -s) = "Darwin" ] && export OSX=1 && export UNIX=1
[ $(uname -s) = "Linux" ] && export LINUX=1 && export UNIX=1
uname -s | grep -q "_NT-" && export WINDOWS=1

# Fix systems missing $USER
[ -z "$USER" ] && export USER=$(whoami)

# Count CPUs for Make jobs
if [ $OSX ]
then
  export CPUCOUNT=$(sysctl -n hw.ncpu)
elif [ $LINUX ]
then
  export CPUCOUNT=$(getconf _NPROCESSORS_ONLN)
else
  export CPUCOUNT="1"
fi

if [ "$CPUCOUNT" -gt 1 ]
then
  export MAKEFLAGS="-j$CPUCOUNT"
  export BUNDLE_JOBS="$CPUCOUNT"
fi

# Setup paths

remove_from_path() {
  [ -d $1 ] || return
  # Doesn't work for first item in the PATH but I don't care.
  export PATH=$(echo $PATH | sed -e "s|:$1||") 2>/dev/null
}

add_to_path_start() {
  [ -d $1 ] || return
  remove_from_path "$1"
  export PATH="$1:$PATH"
}

add_to_path_end() {
  [ -d "$1" ] || return
  remove_from_path "$1"
  export PATH="$PATH:$1"
}

force_add_to_path_start() {
  remove_from_path "$1"
  export PATH="$1:$PATH"
}

add_to_path_start "$HOME/bin"
add_to_path_start "/usr/local/bin"
add_to_path_start "/usr/local/sbin"

quiet_which() {
  which $1 &>/dev/null
}

. "$(brew --prefix asdf)/asdf.sh"
export ASDF_DATA_DIR=$ASDF_DIR

export HOMEBREW_PREFIX="$(brew --prefix)"
export EDITOR=vim
export BROWSER="google chrome canary"
export NLTK_DATA="$HOME/nltk_data"
export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
# export R_HOME="$HOMEBREW_PREFIX/opt/r/lib/R"
# export R_HOME="$HOMEBREW_PREFIX/opt/r-x11/lib/R"
export RSTUDIO_WHICH_R="/usr/local/bin/R"
export GOPATH=$(go env GOPATH)
add_to_path_start "$GOPATH/bin"
export ANDROID_HOME="$HOMEBREW_PREFIX/opt/android-sdk"
export PIPENV_DEFAULT_PYTHON_VERSION="3.7"
export PIPENV_VENV_IN_PROJECT=1
export BAT_PAGER=''
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export ASDF_SKIP_RESHIM=1 # manually run: asdf reshim nodejs

if [ $OSX ]; then
  quiet_which brew && export HOMEBREW_CASK_OPTS="--appdir=/Applications"
  add_to_path_end /Applications/Xcode.app/Contents/Developer/usr/bin
  add_to_path_end /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
  add_to_path_end "$HOMEBREW_PREFIX/opt/git/share/git-core/contrib/diff-highlight"
fi

add_to_path_end /usr/local/texlive/2017/bin/x86_64-darwin

add_to_path_start "/usr/local/opt/qt/bin"
add_to_path_start "$HOME/tizen-studio/tools/ide/bin"
add_to_path_start "$HOME/tizen-studio/tools"

# Add to PATH even if the folder doesn't exist yet to optimize
# pipx first time experience
force_add_to_path_start "$HOME/.local/bin"

# Look in ./bin but do it last to avoid weird `which` results.
force_add_to_path_start "bin"
