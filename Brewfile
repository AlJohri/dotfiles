# Install Taps

tap 'homebrew/core'

tap 'caskroom/cask' # gui apps
tap 'caskroom/versions' # multiple versions of existing gui applications
tap 'caskroom/fonts' # fonts

tap 'homebrew/services' # brew services command
tap 'homebrew/versions' # multiple versions of existing packages
tap 'homebrew/dupes' # apps that are all provided b OS X

tap 'homebrew/science' # scientific packages
tap 'homebrew/binary' # closed-source packages with only binaries

cask_args appdir: '/Applications'

# -------------------------------------

# Get started faster
cask 'google-chrome-beta'
cask 'iterm2-nightly' # terminal emulator
cask 'flash' # flash player plugin (pkg installer)

# Install Essential Brew and Brew Casks
cask 'java6' # required for all JetBrains products
cask 'java' # unless system '/usr/libexec/java_home --failfast' # (pkg installer)
cask 'xquartz' # (pkg installer)
brew 'openssl'

# Python Anaconda 3
cask 'anaconda' unless File.directory?(ENV['HOME'] + '/anaconda3')
cask 'charles'
cask 'gitter'
cask 'skitch'
cask 'teamviewer'
cask 'textual'
cask 'colloquy'
cask 'balsamiq-mockups'

cask 'sublime-text3' # code editor
cask 'pycharm-ce'

# -------------------------------------

# Apps

# Browsers
cask 'firefoxdeveloperedition' # ff developer edition

cask 'logitech-control-center' # to program mouse butons (pkg installer, requires input to close dialog)
cask 'logitech-unifying' # for mouse + keyboard (pkg installer, requires input to close dialog)

cask 'sizeup' # snap windows by mouse
cask 'cinch' # control window placement via hotkeys
cask 'the-unarchiver' # better unarchiving tool
cask 'evernote' # note taker
cask 'insync' # sync google drive documents
cask 'dropbox' # sync files
cask 'skype' # video chat
cask 'google-hangouts' # also video chat (pkg installer)
cask 'slack' # team communication
cask 'spotify' # streaming music player
cask 'vlc' # video player
cask 'caffeine' # prevent computer from going to sleep
cask 'fluid'
cask 'flip4mac' # play windows media on mac (pkg installer)
cask 'transmission'
cask 'bartender'
cask 'calibre'
cask 'android-file-transfer'

cask 'osxfuse'
cask 'sshfs'

# [Brew Cask] Non-essential Apps
cask 'airserver'
cask 'licecap' # gif creator
cask 'macdown' # markdown editor
cask 'audacity' # audio recording
cask 'ccleaner'
cask 'paintbrush' # another ms paint
cask 'mac-linux-usb-loader' # create mac bootable usb flash drives (and potentially windows as well if uefi?)
cask 'unetbootin' # create windows bootable usb flash drives (and potentially mac as well if uefi?)

# [Brew Cask] Quick Look Plugins
# https://github.com/sindresorhus/quick-look-plugins
cask 'qlcolorcode' # syntax highlighting
cask 'qlstephen'
cask 'qlmarkdown' # markdown
cask 'quicklook-json' # json
# cask 'quicklook-csv' # csv (default csv render is better)
cask 'webpquicklook'
cask 'provisionql' # ipa files

# Misc
brew 'jack', restart_service: :changed

# Personal PVR
# cask 'plex-media-server'
# brew 'sickbeard', restart_service: :changed
# brew 'couchpotatoserver', restart_service: :changed
# brew 'headphones', restart_service: :changed

# Set App Defaults
brew 'duti'

# -------------------------------------

# Development

# Command Line Tools
brew 'coreutils'
brew 'moreutils' # cool cmdline utilites like sponge
brew 'homebrew/dupes/rsync'
# brew 'diffutils'
# brew 'findutils' '--with-default-names'
# brew 'homebrew/dupes/grep' '--with-default-names'
brew 'the_silver_searcher'
brew 'tree'
brew 'vim', args: ['override-system-vi', 'without-python']
brew 'colordiff' # color plain diff output
brew 'memtester'
cask 'ngrok' # local tunnel
brew 'ack' # search tool like grep, but optimized for programmers
brew 'lynx' # text only browser
brew 'shellcheck'
brew 'wget', args: ['with-iri']
brew 'pcre' # perl-compatible Regular Expressions
brew 'rename' # Perl-powered file rename script
brew 'watch'
brew 'md5sha1sum'
brew 'pigz' # parallel implementation of gzip
brew 'docker' # containers
brew 'docker-machine'
brew 'ssh-copy-id'
brew 'getxbook' # ebook downloader
brew 'gist' # gist uploader
brew 'awscli' # aws cli
brew 'ec2-api-tools'
brew 'cheat' # short man page for commands
brew 'docker-clean'
brew 'dos2unix'
brew 'jq'
brew 'mackup'
brew 'cowsay'
brew 'fortune'
brew 'archey'
brew 'tor'
brew 'jsonpp'
brew 'htop-osx'
brew 'most'
brew 'ncdu' # its like daisy disk for the command line
brew 'pidof'
brew 'sl'

# Libraries
brew 'pandoc'
brew 'readline' # used by bash, postgresql, r, sqlite, tig, and more
brew 'xz' # general purpose data compresson, needed by ag, r, and imagemagick
brew 'qt' # qt gui framework
brew 'tcl-tk' # another gui framework
brew 'wxmac' # wxWidgets, a cross-platform C++ GUI toolkit (for OS X)
brew 'libxml2', args: ['with-python']
brew 'libxslt'
brew 'ctags'
brew 'reattach-to-user-namespace' # Reattach process (e.g., tmux) to background
brew 'graphviz'
brew 'libyaml'
brew 'automake'
brew 'cmake'
brew 'scons'
brew 'libtool'
brew 'autoconf'
brew 'libevent'
brew 'json-c' # for postgis
brew 'proj' # for postgis
brew 'cgal' # for postgis
brew 'sfcgal' # for postgis
brew 'boost' # for postgis
brew 'liblwgeom' # for postgis
brew 'swig'
brew 'libmpc' # C library for the arithmetic of high precision complex numbers
brew 'gmp' # GNU multiple precision arithmetic library
brew 'mpfr' # C library for multiple-precision floating-point computations
brew 'isl' # Integer Set Library for the polyhedral model
brew 'fftw' # C routines to compute the Discrete Fourier Transform
brew 'berkeley-db' # High performance key/value database, dependency for jack
brew 'eigen'
brew 'icu4c'
brew 'freexl' # Library to extract data from Excel .xls files, for postgis
brew 'gdal'
brew 'geos'
brew 'glib' # Core application library for C
brew 'libspatialite' # Adds spatial SQL capabilities to SQLite, libspatialite
brew 'lzlib' # Data compression library, lzlib
brew 'pkg-config'
brew 'libffi'
brew 'libidn'
brew 'ilmbase'
brew 'popt' # Library like getopt(3) with a number of enhancements
brew 'gobject-introspection'
brew 'gdbm' # GNU database manager
brew 'xvid' # high-quality MPEG-4 video library

# Image, Music, Video Libararies
brew 'homebrew/versions/openjpeg21'
brew 'ffmpeg'
brew 'sdl'
brew 'sdl_image'
brew 'sdl_mixer'
brew 'sdl_ttf'
brew 'smpeg'
brew 'gettext'
brew 'pango'
brew 'cairo'
brew 'librsvg'
brew 'libcroco' # CSS parsing and manipulation toolkit for GNOME
brew 'ghostscript'
brew 'libffi'
brew 'gd' # graphics library to dynamically manipulate images
brew 'gdk-pixbuf'
brew 'webp'
brew 'libpng'
brew 'jpeg'
brew 'libtiff'
brew 'freetype'
brew 'fontconfig'
brew 'pixman'
brew 'lame'
brew 'libogg'
brew 'libvorbis'
brew 'x264'
brew 'libsndfile' # dependency for jack
brew 'flac' # free lossless audio codec, dependency for jack
brew 'libsamplerate' # dependency for jack
brew 'giflib' # GIF library using patented LZW algorithm
brew 'libgeotiff'
brew 'portmidi'
brew 'little-cms2'
brew 'harfbuzz'
brew 'openexr' # OpenEXR ILM Base libraries (high dynamic-range image file format)
brew 'imagemagick', args: ['with-fontconfig', 'with-ghostscript', 'with-jp2', 'with-librsvg', 'with-libtiff', 'with-webp']
brew 'graphicsmagick'

# Languages, Compilers, and SDKs
brew 'gcc'
brew 'homebrew/science/r' #'with-openblas'
cask 'rstudio' # gui for R
brew 'android-sdk'
cask 'android-studio' # gui for android development
brew 'r'
brew 'node'
cask 'julia'
brew 'scala'
brew 'maven' # java
brew 'gradle' # java
brew 'lua'
brew 'leiningen' # clojure
brew 'octave' # matlab-esque

brew 'hdf5'
brew 'hadoop'
brew 'apache-spark'


brew 'pyenv'
brew 'pyenv-which-ext'
brew 'pyenv-virtualenvwrapper'

brew 'ruby-build'
brew 'rbenv'

brew 'go'
brew 'erlang'
# brew 'ghc'
# brew 'lua'
# brew 'scala'

# Version Control
brew 'git'
brew 'git-lfs'
brew 'tig' # text interface git
brew 'hub' # Since v2.2.0, gh has been merged into hub.
brew 'git-flow'
cask 'sourcetree'
brew 'svn'
brew 'mercurial'

# [Brew Cask] Development
cask 'pgadmin3'
cask 'psequel'
cask 'sqlitebrowser' # sqlite gui
cask 'virtualbox' # virtual os / emulators (pkg installer)
cask 'vagrant' # package virtual envs for development (pkg installer)
cask 'sequel-pro' # mysql gui
cask 'macfusion' # use sublime via ssh (sshfs)
cask 'arduino'
cask 'weka'
cask 'tabula'
cask 'gephi'
cask 'pycharm'

# Heroku
brew 'heroku'
# Shells
brew 'bash'
brew 'bash-completion'
brew 'zsh', args: ['without-etcdir']
brew 'zsh-syntax-highlighting'

# -------------------------------------

# Julia Library (iJulia) Dependencies
brew 'nettle'
brew 'zmq'

# -------------------------------------

# Databases and Document Stores
brew 'mysql', restart_service: :changed
brew 'postgresql', args: ['with-python'], restart_service: :changed
brew 'postgis'
brew 'sqlite', args: ['with-functions']
brew 'mongodb', args: ['with-openssl'], restart_service: :changed
# brew 'rethinkdb', restart_service: :changed
brew 'redis', restart_service: :changed # in memory key value data store
brew 'elasticsearch', restart_service: :changed # document search based on lucene
brew 'solr', restart_service: :changed # document search based on lucene
brew 'memcached', restart_service: :changed
brew 'rabbitmq', restart_service: :changed # message queue / broker
brew 'rabbitmq-c' # message queue / broker
brew 'zookeeper', restart_service: :changed # message queue
brew 'kafka', restart_service: :changed # message queue
