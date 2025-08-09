#!/bin/bash

# Exit immeecho "INFO: Configuring Git..."
git config --global user.name "$git_name"
git config --global user.email "$git_email"

# Git commit signing configuration
echo "INFO: Setting up Git commit signing..."
git config --global commit.gpgsign true
git config --global gpg.program "$(which gpg)"

# Add a note about generating a GPG key for signing if not already set up
echo ""
echo "NOTE: To set up Git commit signing with GPG:"
echo "  1. Generate a GPG key: gpg --full-generate-key"
echo "  2. Find your key ID: gpg --list-secret-keys --keyid-format=long"
echo "  3. Set it in Git: git config --global user.signingkey YOUR_KEY_ID"
echo "  4. Add your key to GitHub/GitLab: gpg --armor --export YOUR_KEY_ID"
echo ""

# Configure common Git aliases
git config --global alias.grum "rebase upstream main"
git config --global alias.gfu "fetch upstream"
git config --global alias.gsw "switch"
git config --global alias.gl "log"
git config --global alias.gar "remote add"
git config --global init.defaultBranch "main"f a command exits with a non-zero status
set -e

# Give people a chance to retry running the installation
trap 'echo "installation failed! You can retry by re-running' ERR

# prompt for full name email for github
read -p "Enter your full name: " full_name
read -p "Enter your email address: " email

# basic setup and updates
echo "INFO: Updating system and installing base packages..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y git htop tree curl wget zsh  \
  apt-transport-https ca-certificates gnupg lsb-release software-properties-common

# set shell to zsh
echo "INFO: Setting Zsh as the default shell for $USER..."
chsh -s $(which zsh) "$USER"


echo "INFO: Configuring Git..."
git config --global user.name "$full_name"
git config --global user.email "$email"
git config --global alias.grum "rebase upstream main"
git config --global alias.gfu "fetch upstream"
git config --global alias.gsw "switch"
git config --global alias.gl "log"
git config --global alias.gar "remote add"
git config --global init.defaultBranch "main"


echo "INFO: Generating SSH key for GitHub..."
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
  eval "$(ssh-agent -s)"
  ssh-add "$HOME/.ssh/id_ed25519"
  echo "INFO: SSH key generated. Public key:"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo "INFO: Copy the above public key and add it to your GitHub account: https://github.com/settings/keys"
else
  echo "INFO: SSH key already exists at $HOME/.ssh/id_ed25519"
fi

# install python using deadsnakes
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.9 python3.9-venv python3.9-dev
sudo apt install -y python3.10 python3.10-venv python3.10-dev
sudo apt install -y python3.11 python3.11-venv python3.11-dev
sudo apt install -y python3.13 python3.13-venv python3.13-dev

# Install nvm & node lts
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install --lts

# Desktop software
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    echo "INFO: Adding external repositories for Signal, VS Code, and Edge..."

    # Signal
    signal_keyring="/usr/share/keyrings/signal-desktop-keyring.gpg"
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | sudo tee "$signal_keyring" > /dev/null
    echo "deb [arch=amd64 signed-by=$signal_keyring] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal-xenial.list > /dev/null

    # VS Code
    vscode_keyring="/usr/share/keyrings/packages.microsoft.gpg"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee "$vscode_keyring" > /dev/null
    echo "deb [arch=amd64 signed-by=$vscode_keyring] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    # Microsoft Edge Beta
    edge_keyring="/usr/share/keyrings/microsoft-edge.gpg"
    curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee "$edge_keyring" > /dev/null
    echo "deb [arch=amd64 signed-by=$edge_keyring] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list > /dev/null
    echo "INFO: Updating package lists and installing all applications..."
    sudo apt update

    # Install apps from new repositories
    sudo apt install -y signal-desktop code microsoft-edge-beta

    # Install .deb packages
    docker_deb="docker-desktop-amd64.deb"
    chrome_deb="google-chrome-beta_current_amd64.deb"
    mullvad_deb="mullvad.deb"

    echo "INFO: Installing Docker Desktop..."
    wget "https://desktop.docker.com/linux/main/amd64/$docker_deb" -O "$docker_deb"
    sudo apt install -y ./$docker_deb
    rm "$docker_deb"

    echo "INFO: Installing Google Chrome Beta..."
    wget "https://dl.google.com/linux/direct/$chrome_deb"
    sudo apt install -y ./$chrome_deb
    rm "$chrome_deb"

    echo "INFO: Installing Mullvad VPN..."
    wget "https://mullvad.net/download/app/deb/latest" -O "$mullvad_deb"
    sudo apt install -y ./$mullvad_deb
    rm "$mullvad_deb"



    # Install Cryptomator (AppImage)
    echo "INFO: Installing Cryptomator (AppImage)..."
    cryptomator_appimage="$HOME/.local/bin/cryptomator.AppImage"
    mkdir -p "$HOME/.local/bin"
    wget "https://github.com/cryptomator/cryptomator/releases/download/1.17.1/cryptomator-1.17.1-x86_64.AppImage" -O "$cryptomator_appimage"
    chmod +x "$cryptomator_appimage"
    echo "INFO: Cryptomator AppImage downloaded to $cryptomator_appimage. You can run it from your applications menu or with: $cryptomator_appimage"



    # Install qBittorrent from PPA
    echo "INFO: Adding qBittorrent PPA and installing..."
    sudo add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
    sudo apt update
    sudo apt install -y qbittorrent


    # Install Wireshark
    echo "INFO: Pre-answering Wireshark debconf prompt to avoid blocking..."
    echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
    echo "INFO: Installing Wireshark..."
    sudo apt install -y wireshark

    # Install from script
    echo "INFO: Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh

    # Install VLC
    echo "INFO: Installing VLC..."
    sudo apt install -y vlc

    # -------------------------------------------------------------------------------
    # 4. PIN TO GNOME DOCK
    #-------------------------------------------------------------------------------
    echo "INFO: Pinning Google Chrome Beta, Signal, and VS Code to the dock..."
    gsettings set org.gnome.shell favorite-apps "[ 'google-chrome-beta.desktop', 'signal-desktop.desktop', 'code.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop' ]"

fi

sudo apt autoremove -y
echo "INFO: Finished installing applications."