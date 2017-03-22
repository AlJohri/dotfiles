cask_args appdir: '/Applications'

tap 'homebrew/core'
tap 'caskroom/cask'
tap 'caskroom/versions'
tap 'caskroom/fonts'
tap 'homebrew/services'
tap 'homebrew/versions'
tap 'homebrew/dupes'
tap 'homebrew/science'
tap 'homebrew/binary'

brew 'awscli'
brew 'cheat'
brew 'colordiff'
brew 'docker-clean'
brew 'dos2unix'
brew 'duti'
brew 'gist'
brew 'go'
brew 'gpg-agent'
brew 'heroku'
brew 'hub'
brew 'jq'
brew 'jsonpp'
brew 'leiningen'
brew 'mas'
brew 'mercurial'
brew 'mongodb', restart_service: :changed
brew 'most'
brew 'mysql', restart_service: :changed
brew 'ncdu'
brew 'node'
brew 'nodenv'
brew 'openssl'
brew 'postgresql', restart_service: :changed
brew 'postgis'
brew 'pyenv'
brew 'pyenv-virtualenvwrapper'
brew 'python'
brew 'python3'
brew 'rbenv'
brew 'rbenv-default-gems'
brew 'redis', restart_service: :changed
brew 'ripgrep'
brew 'ruby-build'
brew 'sl'
brew 'svn'
brew 'tig'
brew 'tor', restart_service: :changed
brew 'tree'
brew 'reattach-to-user-namespace'
brew 'wget'
brew 'zsh-syntax-highlighting' # antigen ?
brew 'memtester'
brew 'shellcheck'
brew 'watch'
brew 'md5sha1sum'
brew 'ssh-copy-id'
brew 'ec2-api-tools'
brew 'cowsay'
brew 'fortune'
brew 'archey'
brew 'jsonpp'
brew 'htop-osx'
brew 'pidof'

cask 'google-chrome-beta' unless File.directory?("/Applications/Google Chrome.app")
cask 'firefoxdeveloperedition'
cask 'docker'
cask 'ngrok'
cask 'virtualbox'
cask 'vagrant'
cask 'atom'
cask 'iterm2'
cask 'sublime-text'
cask 'pycharm-ce'
cask 'java' unless system '/usr/libexec/java_home --failfast'
cask 'xquartz'

cask 'keepingyouawake'
cask 'private-internet-access'

brew 'libxml2'
brew 'xslt'
brew 'pyqt5'
brew 'numpy', args: ['without-python', 'with-python3']
brew 'scipy', args: ['without-python', 'with-python3']
brew 'matplotlib', args: ['without-python', 'with-python3', 'with-pyqt5']

cask 'slack'
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
  
  mas '1Password', id: 443987910
  mas 'Pocket', id: 568494494
  mas 'DaisyDisk', id: 411643860
  mas 'Leaf', id: 576338668
  mas 'Wunderlist', id: 410628904

	cask 'nteract'
	cask 'flash'
	cask 'logitech-unifying'
	cask 'logitech-options'  

	brew 'gcc'
	brew 'r'
	cask 'rstudio'
	brew 'android-sdk'
	cask 'android-studio'
	brew 'node'
	cask 'julia'
	brew 'scala'
	brew 'ghc'
	brew 'erlang'
	brew 'maven' # java
	brew 'gradle' # java
	brew 'lua'
	brew 'octave' # matlab-esque

	brew 'hdf5'
	brew 'hadoop'
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
	# brew 'coreutils'
	# brew 'moreutils' # cool cmdline utilites like sponge
	# brew 'homebrew/dupes/rsync'
	# brew 'diffutils'
	# brew 'findutils' '--with-default-names'
	# brew 'homebrew/dupes/grep' '--with-default-names'

	cask 'pgadmin3'
	cask 'psequel'
	cask 'postico'
	cask 'sqlitebrowser' # sqlite gui
	cask 'virtualbox' # virtual os / emulators (pkg installer)
	cask 'vagrant' # package virtual envs for development (pkg installer)
	cask 'sequel-pro' # mysql gui
	cask 'macfusion' # use sublime via ssh (sshfs)
	cask 'arduino'
	cask 'weka'
	cask 'tabula'
	cask 'gephi'

	cask 'airserver'
	cask 'macdown'
	cask 'audacity'
	cask 'ccleaner'
	cask 'paintbrush'
	cask 'mac-linux-usb-loader'
	cask 'unetbootin'

	cask 'charles'
	cask 'gitter'
	cask 'skitch'
	cask 'teamviewer'
	cask 'textual'
	cask 'colloquy'
	cask 'balsamiq-mockups'

	cask 'sizeup'
	cask 'cinch'
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
