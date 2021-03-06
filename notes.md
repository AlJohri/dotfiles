#### Install XCode CLT
```
xcode-select --install
sudo xcodebuild -license
```

#### Add Homebrew Bash/Zsh to /etc/paths
this is a better approach: https://github.com/thoughtbot/laptop/pull/440/files
```
SHELLS_FILE="$(cat $HOME/laptop/templates/shells 2>/dev/null || curl -Ls http://aljohri.com/laptop/templates/shells)"
if [ "x$SHELLS_FILE" != "x$(cat /etc/shells)" ]; then
  echo "Copy custom /etc/paths to allow for homebrew installed shells"
  sudo sh -c "echo '$SHELLS_FILE' > /etc/shells"
fi
```

#### Changing shell to Homebrew ZSH (requires sudo)
```
REALSHELL=$(dscl . -read "/Users/$USER/" UserShell | awk '{ print $2 }')
if [ "$REALSHELL" != "/usr/local/bin/zsh" ]; then
    echo "Switch to /usr/local/bin/zsh instead of /bin/zsh"
    echo "Changing your $REALSHELL shell to /usr/local/bin/zsh ..."
    chsh -s "$(which zsh)"
fi
```

Another approach from thoughtbot/laptop
https://github.com/thoughtbot/laptop/blob/master/mac#L61
```
update_shell() {
  local shell_path;
  shell_path="$(which zsh)"

  fancy_echo "Changing your shell to zsh ..."
  if ! grep "$shell_path" /etc/shells > /dev/null 2>&1 ; then
    fancy_echo "Adding '$shell_path' to /etc/shells"
    sudo sh -c "echo $shell_path >> /etc/shells"
  fi
  chsh -s "$shell_path"
}

case "$SHELL" in
  */zsh)
    if [ "$(which zsh)" != '/bin/zsh' ] ; then
      update_shell
    fi
    ;;
  *)
    update_shell
    ;;
esac
```

#### Install Ruby with Homebrew Openssl (this might happen by default now)
```
RUBY_CONFIGURE_OPTS=--with-openssl-dir=/usr/local/opt/openssl rbenv install -s "$ruby_version"
```

#### Set up Ruby Bundler
```
gem update --system

gem_install_or_update 'bundler'

echo "Configuring Bundler ..."
number_of_cores=$(sysctl -n hw.ncpu)
bundle config --global jobs $((number_of_cores - 1))

rbenv rehash
```

#### Find latest pyenv/rbenv/nodenv minor version given a major version
```
find_latest_python2() {
	pyenv install -l | grep -E '([2])\.([0-9]+)\.([0-9]+)' | grep -v - | tail -1 | sed -e 's/^ *//'
}
python_version2="$(find_latest_python2)"

find_latest_python3() {
	pyenv install -l | grep -E '([3])\.([0-9]+)\.([0-9]+)' | grep -v - | tail -1 | sed -e 's/^ *//'
}
python_version3="$(find_latest_python3)"

echo "$python_version2 $python_version3"
```

#### Set up Jupyter R Kernel
```
Rscript -e "install.packages(c('rzmq','repr','IRkernel','IRdisplay'), repos = c('http://irkernel.github.io/', 'http://cran.rstudio.com/')); IRkernel::installspec()"
```

#### Set up Jupter Julia Kernel
```
julia -e 'Pkg.add("IJulia")'
```

#### Setting environment variables for GUI applications
```
# launchctl `echo setenv RSTUDIO_WHICH_R $RSTUDIO_WHICH_R`
# launchctl `echo setenv JAVA_HOME $JAVA_HOME`
# launchctl `echo setenv ANDROID_SDK_ROOT $ANDROID_SDK_ROOT`
```

#### sublime enable vertical select via keyboard on osx
http://stackoverflow.com/questions/16286374/sublime-text-2-rectangular-or-column-select-by-keyboard-only-on-mac-10-8-3/18957047#18957047

#### Tor

##### Set up
```
brew install tor
brew services start tor
networksetup -setsocksfirewallproxy Wi-Fi 127.0.0.1 9050 off
```

###### Start
```
networksetup -setsocksfirewallproxystate Wi-Fi on
```

###### Stop
```
networksetup -setsocksfirewallproxystate Wi-Fi off
```

#### Sync Browser Bookmarks
Synkmark
- http://www.sheepsystems.com/products/synkmark.html
- http://sheepsystems.com/synkmark/Synkmark.zip
- http://sheepsystems.com/synkmark/Synkmark.dmg

#### Safari
https://github.com/Antrikshy/RecoverTabs
```
wget https://update.adblockplus.org/latest/adblockplussafari.safariextz && open adblockplussafari.safariextz
wget https://s3-us-west-1.amazonaws.com/antrikshyprojects/RecoverTabs.safariextz && open RecoverTabs.safariextz
wget http://pocket-extensions.s3.amazonaws.com/safari/Pocket.safariextz && open Pocket.safariextz
```

#### BasicText
```
wget http://tug.org/cgi-bin/mactex-download/BasicTeX.pkg && open BasicTeX.pkg
sudo chown -R `whoami`:admin /usr/local/texlive
tlmgr install collection-fontsrecommended
```

#### Start GPG Agent (if not already running)
```
startgpg # defined in shrc.sh
```

#### Set up GPG Key

```
gpg --gen-key
```

#### Change GPG Passphrase
```
gpg --passwd al.johri@gmail.com
```

#### Using gpg-preset-passphrase
only applies if you set a passphrase
```
startgpg
echo $GPG_TTY
echo $GPG_AGENT_INFO
echo $KEYGRIP
# make sure the three variables above are defined
echo "yourphasephrasehere" | /usr/local/opt/gpg-agent/libexec/gpg-preset-passphrase -v --preset $KEYGRIP
```

#### python stuff

```

https://docs.python.org/2/library/site.html#site.USER_SITE

# http://joernhees.de/blog/2013/06/08/mac-os-x-10-8-scientific-python-with-homebrew/

# if doing brew install pygame i think??
mv /usr/local/include/python2.7/pygame "/Users/atul/.pyenv/versions/$python_version/include/python2.7/"

# how to install pygame on osx
# https://bitbucket.org/pygame/pygame/issue/82/homebrew-on-leopard-fails-to-install#comment-627494
# brew install sdl sdl_image sdl_mixer sdl_ttf portmidi
# pip install hg+http://bitbucket.org/pygame/pygame
# cp -r pygame /Users/atul/.pyenv/versions/2.7.10/include/python2.7/

# wget http://sourceforge.net/projects/pyqt/files/sip/sip-4.16.4/sip-4.16.4.tar.gz
# tar -xvf sip-4.16.4.tar.gz
# cd sip-4.16.4; /usr/local/bin/python configure.py; make; make install

# wget http://sourceforge.net/projects/pyqt/files/PyQt4/PyQt-4.11.3/PyQt-mac-gpl-4.11.3.tar.gz
# tar -xvf PyQt-mac-gpl-4.11.3.tar.gz
# cd PyQt-mac-gpl-4.11.3; /usr/local/bin/python configure.py --confirm-license; make; make install

pip install virtualenv
pip install virtualenv-clone
pip install virtualenvwrapper

pip install numpy
pip install scipy
pip install scikit-learn
pip install nltk
pip install "ipython[notebook]"
pip install matplotlib
pip install requests
pip install pygments
pip install lxml

python -m nltk.downloader all

# http://matplotlib.org/faq/usage_faq.html#what-is-a-backend

brew install pygame --without-python
brew install numpy --without-python
brew install scipy --without-python
brew install matplotlib --without-python
brew install opencv --without-numpy
brew install pillow --without-python
```

pypy
```
pyenv install pypy-2.6.0
pyenv install pypy3-2.4.0

pyenv shell pypy-2.6.0

pip install git+https://bitbucket.org/pypy/numpy.git
pip install requests lxml cssselect
pip install flask
```

jupyter kernel installation
https://github.com/jupyter/jupyter/issues/52
```
python -m ipykernel install --name <name>
```

#### stanford nlp

http://nlp.stanford.edu/software/corenlp.shtml#Download
wget http://nlp.stanford.edu/software/stanford-corenlp-full-2015-04-20.zip

http://textminingonline.com/how-to-use-stanford-named-entity-recognizer-ner-in-python-nltk-and-other-programming-languages

https://github.com/nltk/nltk/wiki/Installing-Third-Party-Software#stanford-tagger-ner-tokenizer-and-parser
```
export CLASSPATH="$HOME/stanford_nlp/stanford-ner-2015-12-09/stanford-ner.jar"
export CLASSPATH="$CLASSPATH:$HOME/stanford_nlp/stanford-parser-full-2015-12-09/stanford-parser.jar"
export CLASSPATH="$CLASSPATH:$HOME/stanford_nlp/stanford-postagger-full-2015-12-09/stanford-postagger.jar"

export STANFORD_MODELS="$HOME/stanford_nlp/stanford-ner-2015-12-09/classifiers"
export STANFORD_MODELS="$STANFORD_MODELS:$HOME/stanford_nlp/stanford-postagger-full-2015-12-09/models"
export STANFORD_MODELS="$STANFORD_MODELS:$HOME/stanford_nlp/stanford-parser-full-2015-12-09/stanford-parser-3.6.0-models.jar"
```

https://gist.github.com/alvations/e1df0ba227e542955a8a

Issues with Stanford NLP Tools 2015-12-09 and NLTK 3.1. Use develop version for now.

pip install -U "https://github.com/nltk/nltk/archive/develop.zip"

#### prezto theme
```
prompt cloud ➜ red blue
```

#### duti
https://www.chainsawonatireswing.com/2012/09/19/changing-default-applications-on-a-mac-using-the-command-line-then-a-shell-script//?from=@

Set Default Editor

use `com.microsoft.VSCode` or `com.sublimetext.3` or `com.apple.textedit` or `com.macromates.textmate`

```
duti -s com.microsoft.VSCode java all
duti -s com.microsoft.VSCode js all
duti -s com.microsoft.VSCode py all
duti -s com.microsoft.VSCode rb all
duti -s com.microsoft.VSCode sh all
duti -s com.microsoft.VSCode json all
duti -s com.microsoft.Excel csv all
duti -s com.microsoft.VSCode public.plain-text all
duti -s com.microsoft.VSCode public.unix-executable all
duti -s com.microsoft.VSCode public.source-code all
```

Check Default Editor
```
duti -x java
duti -x py
duti -x rb
duti -x sh
```

#### colloquy
```
/usr/libexec/PlistBuddy -c "print :MVChatBookmarks:0:server" ~/Library/Preferences/info.colloquy.plist
/usr/libexec/PlistBuddy -c "print :MVChatBookmarks:1:rooms" ~/Library/Preferences/info.colloquy.plist
/usr/libexec/PlistBuddy -c "print :MVChatBookmarks:1:server" ~/Library/Preferences/info.colloquy.plist
```

#### Links
- https://github.com/thoughtbot/laptop
- https://github.com/18F/laptop
- https://github.com/mathiasbynens/dotfiles/blob/master/.osx
- https://github.com/jjangsangy/Dotfiles

---------------------------------------------------------------

# Notes on changing mac settings via command line

Note: Quick Look doesn't allow selecting text. If you want to select the text in the markdown preview, you will need to enable text selection in Quick Look by running the following in Terminal:

```
defaults write com.apple.finder QLEnableTextSelection -bool TRUE; killall Finder
```

https://raymii.org/s/snippets/OS-X-Enable-Access-for-assistive-devices-via-command-line.html

```

# NOTE: it seems sizeup doesn't require accessibility

/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/SizeUp.app/Contents/Info.plist # com.irradiatedsoftware.SizeUp
/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/Cinch.app/Contents/Info.plist # com.irradiatedsoftware.Cinch-Direct
/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/Karabiner.app/Contents/Info.plist # org.pqrs.Karabiner
/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/Karabiner.app/Contents/Applications/Karabiner_AXNotifier.app/Contents/Info.plist # org.pqrs.Karabiner-AXNotifier

# check if it already exists in db first ?

sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT COUNT(*) from access WHERE client='com.irradiatedsoftware.Cinch-Direct';"

sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT COUNT(*) from access WHERE client='com.irradiatedsoftware.SizeUp';"
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT COUNT(*) from access WHERE client='org.pqrs.Karabiner-AXNotifier';"

sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "INSERT INTO access VALUES('kTCCServiceAccessibility','com.irradiatedsoftware.SizeUp',0,1,1,NULL);"
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "INSERT INTO access VALUES('kTCCServiceAccessibility','com.irradiatedsoftware.Cinch-Direct',0,1,1,NULL);"
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "INSERT INTO access VALUES('kTCCServiceAccessibility','org.pqrs.Karabiner-AXNotifier',0,1,1,NULL);"
```

# Get Full Name
```
dscl . -read /Users/`whoami` FirstName | grep FirstName | awk '{print $2}'
dscl . -read /Users/`whoami` LastName | grep LastName | awk '{print $2}'
```
