set nocompatible
set backspace=indent,eol,start
set number
set ruler
set autoindent
set smartindent
set expandtab
set shiftwidth=4
set tabstop=4
set hlsearch
set incsearch
set mouse=a
set clipboard=unnamed
set title
syntax on

autocmd FileType html setlocal shiftwidth=4 tabstop=4
autocmd FileType python setlocal shiftwidth=4 tabstop=4
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2

autocmd FileType make setlocal noexpandtab
