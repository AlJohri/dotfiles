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
brew 'gist'
brew 'go'
brew 'heroku'
brew 'hub'
brew 'jq'
brew 'jsonpp'
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
brew 'scala'
brew 'sl'
brew 'svn'
brew 'tig'
brew 'tor', restart_service: :changed
brew 'tree'
brew 'duti'
brew 'reattach-to-user-namespace'
brew 'wget'
brew 'zsh-syntax-highlighting' # antigen ?

cask 'docker'
cask 'ngrok'
cask 'virtualbox'
cask 'vagrant'
cask 'atom'
cask 'iterm2'
cask 'sublime-text'
cask 'pycharm-ce'
cask 'java'
cask 'xquartz'

cask 'keepingyouawake'

if ENV['BREWFILE_COMPLETE']

	brew 'gcc'
	brew 'r'
	cask 'rstudio' # gui for R
	brew 'android-sdk'
	cask 'android-studio' # gui for android development
	brew 'node'
	cask 'julia'
	brew 'scala'
	brew 'ghc'
	brew 'erlang'
	brew 'maven' # java
	brew 'gradle' # java
	brew 'lua'
	brew 'leiningen' # clojure
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
