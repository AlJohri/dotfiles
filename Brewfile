cask_args appdir: '/Applications'

tap 'homebrew/core'
tap 'caskroom/cask'
tap 'caskroom/versions'
tap 'caskroom/fonts'
tap 'caskroom/drivers'
tap 'homebrew/services'
tap 'homebrew/versions'
tap 'homebrew/dupes'
tap 'homebrew/science'
tap 'homebrew/binary'
tap 'nodenv/nodenv'

cask 'java' unless system '/usr/libexec/java_home --failfast'
cask 'xquartz'

brew 'awscli'
brew 'coreutils'
brew 'cheat'
brew 'colordiff'
brew 'docker-clean'
brew 'dos2unix'
brew 'duti'
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
brew 'nodenv'
brew 'nodenv/nodenv/nodenv-package-rehash'
brew 'nodenv/nodenv/nodenv-default-packages'
brew 'openssl'
brew 'openconnect'
brew 'pidof'
brew 'postgresql', restart_service: :changed
brew 'postgis'
brew 'pyenv'
brew 'python'
brew 'python3'
brew 'rbenv'
brew 'rbenv-default-gems'
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

cask 'google-chrome-beta' unless File.directory?("/Applications/Google Chrome.app")
cask 'firefoxdeveloperedition'
cask 'docker'
cask 'atom'
cask 'iterm2'
cask 'sublime-text'
cask 'pycharm-ce'
cask 'keepingyouawake'
cask 'slack' unless File.directory?("/Applications/Slack.app")
cask 'vlc'
cask 'spotify'
cask 'dropbox'

# https://github.com/sindresorhus/quick-look-plugins
cask 'qlcolorcode'
cask 'qlstephen'
cask 'qlmarkdown'
cask 'quicklook-json'
# cask 'quicklook-csv' # csv (default csv render is better)
cask 'webpquicklook'
cask 'provisionql'

if ENV['BREWFILE_COMPLETE']
  cask 'nteract'
  brew 'gcc'
  brew 'r'
  cask 'rstudio'
  cask 'android-sdk'
  cask 'android-studio'
  cask 'julia'
  brew 'scala'
  brew 'ghc'
  brew 'erlang'
  brew 'maven'
  brew 'gradle'
  brew 'lua'
  brew 'octave'
  brew 'hdf5'
  brew 'apache-spark'
  brew 'rethinkdb', restart_service: :changed
  brew 'elasticsearch', restart_service: :changed
  brew 'solr', restart_service: :changed
  brew 'memcached', restart_service: :changed
  brew 'rabbitmq', restart_service: :changed
  brew 'rabbitmq-c'
  brew 'zookeeper', restart_service: :changed
  brew 'kafka', restart_service: :changed
end

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
  mas '1Password', id: 443987910
  mas 'Pocket', id: 568494494
  mas 'DaisyDisk', id: 411643860
  mas 'Leaf', id: 576338668
  mas 'Wunderlist', id: 410628904
  mas 'KyPass Companion', id: 555293879

  cask 'pritunl'
  cask 'ngrok'
  cask 'caskroom/drivers/logitech-options'
  cask 'virtualbox'
  cask 'vagrant'
  cask 'teamviewer'
  cask 'private-internet-access'
  cask 'flash-npapi'
  brew 'zzz'
end
