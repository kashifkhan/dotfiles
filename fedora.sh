#!/bin/bash
set -e
trap 'echo "installation failed! You can retry by re-running the script."' ERR

# basic setup and updates
echo "INFO: Updating system and installing base packages..."
sudo dnf update -y

# Get the free repository (most stuff you need)
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Get the nonfree repository (NVIDIA drivers, some codecs)
sudo dnf install -y \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# See what can be updated
sudo fwupdmgr get-devices

# Refresh the firmware database
sudo fwupdmgr refresh --force

# Check for updates
sudo fwupdmgr get-updates

# Apply them
sudo fwupdmgr update

# Remove the limited Fedora repo
flatpak remote-delete fedora

# Add the real Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Update everything
flatpak update --appstream

# Update everything so it all plays nice together
sudo dnf group upgrade core -y
sudo dnf check-update

sudo dnf install -y git htop tree curl wget zsh

# set shell to zsh
echo "INFO: Setting Zsh as the default shell for $USER..."
chsh -s $(which zsh) "$USER"

# prompt for full name email for github
read -p "Enter your full name: " full_name
read -p "Enter your email address: " email

# configure git
echo "INFO: Configuring Git..."
git config --global user.name "$full_name"
git config --global user.email "$email"
git config --global init.defaultBranch "main"
git config --global commit.gpgsign true
git config --global gpg.program "$(which gpg)"

# install python
echo "INFO: Installing Python versions..."
sudo dnf install -y python3.9 python3.10 python3.11 python3.12 python3.13
sudo dnf install -y python3.9-venv python3.10-venv python3.11-venv python3.12-venv python3.13-venv

# Install nvm & node lts
echo "INFO: Installing NVM and Node.js LTS..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.zshrc
nvm install --lts

# install vs code
echo "INFO: Installing Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf install code

# install chrome beta
sudo dnf install fedora-workstation-repositories
sudo dnf config-manager setopt google-chrome.enabled=1
sudo dnf install google-chrome-beta

# install edge beta
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo mv /etc/yum.repos.d/packages.microsoft.com_yumrepos_edge.repo /etc/yum.repos.d/microsoft-edge-beta.repo
sudo dnf install microsoft-edge-beta

# mullvad
sudo dnf config-manager addrepo --from-repofile=https://repository.mullvad.net/rpm/stable/mullvad.repo
sudo dnf install mullvad-vpn

# wireshark
sudo dnf install wireshark
sudo usermod -a -G wireshark $USER

# tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# vlc
sudo dnf install vlc

# Replace the neutered ffmpeg with the real one
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

# Install all the GStreamer plugins
sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav lame\* --exclude=gstreamer1-plugins-bad-free-devel

# Install multimedia groups

sudo dnf group install -y multimedia
sudo dnf group install -y sound-and-video

sudo dnf install -y ffmpeg-libs libva libva-utils

# Install the Cisco codec (it's free but weird licensing)
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264

# Enable the Cisco repo
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
sudo dnf update -y




