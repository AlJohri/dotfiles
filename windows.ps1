Set-ExecutionPolicy RemoteSigned -scope CurrentUser
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

scoop bucket add extra
scoop bucket add personal https://github.com/AlJohri/scoop-personal.git

scoop install sudo
scoop install wget
scoop install curl
scoop install windows-terminal
scoop install sublime-text
scoop install vscode
scoop install 1password
scoop install teamviewer
scoop install whatsapp
scoop install skype
scoop install spotify
scoop install vlc
