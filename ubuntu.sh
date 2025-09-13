#!/bin/bash
set -e
trap 'echo "installation failed! You can retry by re-running' ERR

# basic setup and updates
echo "INFO: Updating system and installing base packages..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y git htop tree curl wget zsh  \
  apt-transport-https ca-certificates gnupg lsb-release software-properties-common

# set shell to zsh
echo "INFO: Setting Zsh as the default shell for $USER..."
chsh -s $(which zsh) "$USER"

# prompt for full name email for github
read -p "Enter your full name: " full_name
read -p "Enter your email address: " email

echo "INFO: Configuring Git..."
git config --global user.name "$full_name"
git config --global user.email "$email"
git config --global init.defaultBranch "main"
git config --global commit.gpgsign true
git config --global gpg.program "$(which gpg)"

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
  # Official Signal Desktop repository and key (official instructions)
  wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
  cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
  wget -O signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources
  cat signal-desktop.sources | sudo tee /etc/apt/sources.list.d/signal-desktop.sources > /dev/null
  # Update package lists and install Signal
  sudo apt update && sudo apt install -y signal-desktop

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
  sudo apt install -y code microsoft-edge-beta

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
    echo "INFO: Adding $USER to the wireshark group..."
    sudo usermod -aG wireshark $USER

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

# generate GPG key for git commit sign
gpg --full-generate-key
gpg --list-secret-keys --keyid-format LONG
echo "git config --global user.signingkey <your-key-id>"
echo "INFO: Copy the above command and run it to set your GPG key for Git signing."
echo "gpg --armor --export <your-key-id>"
echo "INFO: Copy the above command and run it to export your GPG key for GitHub."

echo "INFO: Finished installing applications."