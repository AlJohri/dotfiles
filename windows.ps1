# Getting Started on fresh Computer
#
# winget install --id Git.Git -e
#
# git clone https://github.com/AlJohri/dotfiles.git
#
# Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#
# .\windows.ps1

$ErrorActionPreference = "Stop"

echo "voidtools.Everything"; winget install -e --id voidtools.Everything
echo "PrimateLabs.Geekbench.5"; winget install -e --id PrimateLabs.Geekbench.5
echo "Zoom.Zoom"; winget install -e --id Zoom.Zoom
echo "Valve.Steam"; winget install -e --id Valve.Steam
echo "SublimeHQ.SublimeText.4"; winget install -e --id SublimeHQ.SublimeText.4
echo "TeamViewer.TeamViewer"; winget install -e --id TeamViewer.TeamViewer
echo "VideoLAN.VLC"; winget install -e --id VideoLAN.VLC
echo "Microsoft.VisualStudioCode"; winget install -e --id Microsoft.VisualStudioCode
echo "Iterate.Cyberduck"; winget install -e --id Iterate.Cyberduck
echo "AgileBits.1Password"; winget install -e --id AgileBits.1Password
echo "Docker.DockerDesktop"; winget install -e --id Docker.DockerDesktop
echo "Discord.Discord"; winget install -e --id Discord.Discord
echo "Notion.Notion"; winget install -e --id Notion.Notion
echo "Canonical.Ubuntu"; winget install -e --id Canonical.Ubuntu
echo "OpenJS.NodeJS"; winget install -e --id OpenJS.NodeJS
echo "Python.Python.3.12"; winget install -e --id Python.Python.3.12
echo "TechPowerUp.GPU-Z"; winget install -e --id TechPowerUp.GPU-Z
echo "CPUID.CPU-Z"; winget install -e --id CPUID.CPU-Z
echo "CPUID.HWMonitor"; winget install -e --id CPUID.HWMonitor
echo "JRSoftware.InnoSetup"; winget install -e --id JRSoftware.InnoSetup
echo "OpenWhisperSystems.Signal"; winget install -e --id OpenWhisperSystems.Signal
echo "SlackTechnologies.Slack"; winget install -e --id SlackTechnologies.Slack
echo "PDFLabs.PDFtk.Server"; winget install -e --id PDFLabs.PDFtk.Server
echo "flux.flux"; winget install -e --id flux.flux
echo "Logitech.Options"; winget install -e --id Logitech.Options
echo "Philips.HueSync"; winget install -e --id Philips.HueSync
echo "Rufus.Rufus"; winget install -e --id Rufus.Rufus
echo "Balena.Etcher"; winget install -e --id Balena.Etcher
echo "Neovim.Neovim"; winget install -e --id Neovim.Neovim

git config --global user.email "al.johri@gmail.com"
git config --global user.name "Al Johri"
