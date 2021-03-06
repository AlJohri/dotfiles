# Usage:
# iwr -useb https://raw.githubusercontent.com/AlJohri/dotfiles/master/windows.ps1 | iex

Set-ExecutionPolicy RemoteSigned -scope CurrentUser
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

scoop install git

scoop bucket add extras
scoop bucket add nerd-fonts
scoop bucket add personal https://github.com/AlJohri/scoop-personal.git

scoop install sudo
scoop install curl
scoop install wget
scoop install which

scoop install caffeine
scoop install everything
scoop install geekbench
scoop install googlechrome-beta
scoop install innounp
scoop install skype
scoop install standardnotes
scoop install steam
scoop install sublime-text
scoop install teamviewer
scoop install vlc
scoop install vscode
scoop install whatsapp
scoop install windows-terminal

scoop install personal/cyberduck
scoop install personal/keybase
scoop install personal/spotify
scoop install personal/1password
sudo scoop install nerd-fonts/Delugia-Nerd-Font

sudo Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

scoop install personal/docker

# Within WSL, run:
# git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-wincred.exe"
