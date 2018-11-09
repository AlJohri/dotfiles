tap 'homebrew/services'
tap 'caskroom/cask'
tap 'caskroom/versions'

brew 'openssl'
cask 'java' unless system '/usr/libexec/java_home --failfast'
cask 'xquartz'

brew 'awscli'
brew 'coreutils'
brew 'cheat'
brew 'colordiff'
brew 'dos2unix'
brew 'duti'
brew 'elasticsearch', restart_service: :changed
brew 'fortune'
brew 'ffmpeg'
brew 'gist'
brew 'go'
brew 'gpg-agent'
brew 'heroku'
brew 'htop-osx'
brew 'hub'
brew 'jq'
brew 'jsonpp'
brew 'kafka'
brew 'leiningen'
brew 'libxslt'
brew 'libxml2'
brew 'mas'
brew 'memtester'
brew 'mercurial'
brew 'mongodb', restart_service: :changed
brew 'most'
brew 'moreutils'
brew 'mysql', restart_service: :changed
brew 'ncdu'
brew 'node'
brew 'openssl'
brew 'openconnect'
brew 'pidof'
brew 'postgresql', restart_service: :changed
brew 'postgis'
brew 'pyenv'
brew 'python'
brew 'python@2'
brew 'redis', restart_service: :changed
brew 'ripgrep'
brew 'ruby-build'
brew 'sl'
brew 'shellcheck'
brew 'svn'
brew 'tig'
brew 'tor', restart_service: :changed
brew 'tree'
brew 'reattach-to-user-namespace'
brew 'wget'
brew 'yarn'
brew 'youtube-dl'
brew 'zsh-syntax-highlighting' # antigen ?
brew 'watch'
brew 'md5sha1sum'
brew 'ssh-copy-id'
brew 'ec2-api-tools'
brew 'cowsay'
brew 'archey'
brew 'jsonpp'

cask 'iterm2' unless File.directory?("/Applications/iTerm.app")
cask 'docker' unless File.directory?("/Applications/Docker.app")
cask 'sublime-text' unless File.directory?("/Applications/Sublime Text.app")
cask 'visual-studio-code' unless File.directory?("/Applications/Visual Studio Code.app.app")

cask 'google-chrome-canary'
cask 'google-chrome-beta' unless File.directory?("/Applications/Google Chrome.app")
cask 'keepingyouawake' unless File.directory?("/Applications/KeepingYouAwake.app")
cask 'slack' unless File.directory?("/Applications/Slack.app")
cask 'dropbox' unless File.directory?("/Applications/Dropbox.app")
cask 'vlc'
cask 'spotify'

# https://github.com/sindresorhus/quick-look-plugins
cask 'qlcolorcode'
cask 'qlstephen'
cask 'qlmarkdown'
cask 'quicklook-json'
cask 'webpquicklook'
cask 'provisionql'

if ENV['BREWFILE_EXTRA']

  # look into these more:
  # brew 'homebrew/dupes/rsync'
  # brew 'diffutils'
  # brew 'findutils' '--with-default-names'
  # brew 'homebrew/dupes/grep' '--with-default-names'

  cask 'pgadmin3'
  cask 'psequel'
  cask 'postico'
  cask 'sqlitebrowser' # sqlite gui
  cask 'sequel-pro' # mysql gui
  cask 'osxfuse'
  cask 'macfusion' # use sublime via ssh (sshfs)
  cask 'arduino'
  cask 'weka'
  cask 'tabula'
  cask 'gephi'

  cask 'airserver'
  cask 'macdown'
  cask 'ccleaner'
  cask 'paintbrush'
  cask 'mac-linux-usb-loader'
  cask 'unetbootin'

  cask 'charles'
  cask 'gitter'
  cask 'skitch'
  cask 'textual'
  cask 'balsamiq-mockups'

  cask 'sizeup'
  cask 'cinch'
  cask 'carbon-copy-cloner'
  cask 'bartender'
  cask 'the-unarchiver'
  cask 'evernote'
  cask 'insync'
  cask 'skype'
  cask 'google-hangouts'
  cask 'fluid'
  cask 'flip4mac'
  cask 'transmission'
  cask 'bartender'
  cask 'calibre'
  cask 'licecap'

  brew 'jack', restart_service: :changed
end

# requires password or interaction from user
if ENV['BREWFILE_INTERACTIVE']
  mas '1Password', id: 1333542190
  mas 'Pocket', id: 568494494
  mas 'DaisyDisk', id: 411643860
  mas 'Leaf', id: 576338668
  mas 'Todoist', id: 585829637

  cask 'ngrok'
  cask 'caskroom/drivers/logitech-options'
  cask 'virtualbox'
  cask 'teamviewer'
  cask 'private-internet-access'
  cask 'flash-npapi'
  brew 'zzz'
end
