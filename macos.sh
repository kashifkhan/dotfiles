#!/bin/bash
set -e
trap 'echo "Installation failed! You can retry by re-running"' ERR

echo "INFO: macOS Setup Script Starting..."

# -------------------------------------------------------------------------------
# 1. INSTALL HOMEBREW (PACKAGE MANAGER FOR MACOS)
# -------------------------------------------------------------------------------
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# -------------------------------------------------------------------------------
# 2. INSTALL BASIC CLI TOOLS
# -------------------------------------------------------------------------------
echo "INFO: Installing CLI tools..."
brew install git curl wget

# -------------------------------------------------------------------------------
# 3. GIT SETUP
# -------------------------------------------------------------------------------
# Prompt for full name email for GitHub
read -p "Enter your full name: " full_name
read -p "Enter your email address: " email

echo "INFO: Configuring Git..."
git config --global user.name "$full_name"
git config --global user.email "$email"
git config --global alias.grum "rebase upstream main"
git config --global alias.gfu "fetch upstream"
git config --global alias.gsw "switch"
git config --global alias.gl "log"
git config --global alias.gar "remote add"
git config --global init.defaultBranch "main"
git config --global commit.gpgsign true
git config --global gpg.program "$(which gpg)"

# -------------------------------------------------------------------------------
# 4. DEV ENVIRONMENT SETUP
# -------------------------------------------------------------------------------
# Install Python versions
echo "INFO: Installing Python versions..."
brew install python@3.9 python@3.10 python@3.11 python@3.12 python@3.13

# Install NVM & Node.js LTS
echo "INFO: Installing NVM and Node.js LTS..."
brew install nvm
mkdir -p ~/.nvm

echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc
echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"' >> ~/.zshrc
  

# Load NVM and install Node.js
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Install Node.js LTS
nvm install --lts

# -------------------------------------------------------------------------------
# 5. SSH & GPG KEY SETUP FOR GITHUB
# -------------------------------------------------------------------------------
echo "INFO: Setting up SSH & GPG keys for GitHub..."

# Set up SSH key for GitHub
ssh_dir="$HOME/.ssh"
ssh_key="$ssh_dir/id_ed25519"

if [[ ! -f "$ssh_key" ]]; then
    echo "INFO: Creating SSH directory if it doesn't exist..."
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    echo "INFO: Generating SSH key for GitHub..."
    ssh-keygen -t ed25519 -C "$email" -f "$ssh_key"
    
    # Start ssh-agent
    eval "$(ssh-agent -s)"
    
    # Add config file to manage connections if it doesn't exist
    if [[ ! -f "$ssh_dir/config" ]]; then
        echo "Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $ssh_key" > "$ssh_dir/config"
        chmod 600 "$ssh_dir/config"
    fi
    
    # Add SSH key to keychain and agent
    ssh-add --apple-use-keychain "$ssh_key"
    
    echo "INFO: SSH key generated. Public key:"
    cat "$ssh_key.pub"
    echo "INFO: Copy the above public key and add it to your GitHub account: https://github.com/settings/keys"
else
    echo "INFO: SSH key already exists at $ssh_key"
fi

# Set up GPG for commit signing
echo "INFO: Setting up Git commit signing with GPG..."

# Install GPG if not already installed
brew install gnupg pinentry-mac

# Configure GPG to use the macOS keychain
if [[ ! -f "$HOME/.gnupg/gpg-agent.conf" ]]; then
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"
    echo "pinentry-program /opt/homebrew/bin/pinentry-mac" > "$HOME/.gnupg/gpg-agent.conf"
    chmod 600 "$HOME/.gnupg/gpg-agent.conf"
    gpgconf --kill gpg-agent
fi

# Check for existing GPG key
if gpg --list-secret-keys --keyid-format LONG | grep -q "sec"; then
    echo "INFO: Existing GPG key found"
    gpg_key=$(gpg --list-secret-keys --keyid-format LONG | grep "sec" | awk '{print $2}' | cut -d'/' -f2)
    echo "INFO: Using GPG key: $gpg_key"
    git config --global user.signingkey "$gpg_key"
else
    echo "INFO: No GPG key found. Generating a new GPG key..."
    gpg --full-generate-key
    
    # Get the key ID
    gpg_key=$(gpg --list-secret-keys --keyid-format LONG | grep "sec" | head -n1 | awk '{print $2}' | cut -d'/' -f2)
    
    if [[ -n "$gpg_key" ]]; then
        git config --global user.signingkey "$gpg_key"
        echo "INFO: GPG key generated and configured in Git."
        echo "INFO: Your GPG key ID: $gpg_key"
        
        # Export public key for GitHub
        echo "INFO: Your GPG public key (add to GitHub at https://github.com/settings/keys):"
        gpg --armor --export "$gpg_key"
    else
        echo "WARNING: GPG key generation failed or couldn't get key ID."
    fi
fi

# -------------------------------------------------------------------------------
# 6. DESKTOP APPLICATIONS
# -------------------------------------------------------------------------------
echo "INFO: Installing desktop applications..."

# Dev tools
echo "INFO: Installing development tools..."
brew install --cask visual-studio-code docker

# Web browsers
echo "INFO: Installing web browsers..."
brew install --cask google-chrome-beta microsoft-edge firefox

# Communication
echo "INFO: Installing communication tools..."
brew install --cask signal whatsapp

# Utilities
echo "INFO: Installing utilities..."
brew install --cask vlc qbittorrent wireshark cryptomator
brew install --cask mullvadvpn

# Install Tailscale
brew install tailscale
echo "INFO: To start Tailscale service, run: brew services start tailscale"

# -------------------------------------------------------------------------------
# 7. MACOS SPECIFIC SETTINGS
# -------------------------------------------------------------------------------

# add apps to dock
# whatsapp
dockutil --add "/Applications/WhatsApp.app"
dockutil --add "/Applications/Signal.app"
dockutil --add "/Applications/Visual Studio Code.app"

# -------------------------------------------------------------------------------
# 8. FINISH
# -------------------------------------------------------------------------------
echo "INFO: Setup complete! Some changes may require restarting your computer."
echo "INFO: Remember to add your SSH and GPG keys to GitHub."

if [[ "$SHELL" != */zsh ]]; then
    echo "INFO: Note that Zsh has been set as your default shell, but you need to restart your terminal or log out and back in for this change to take effect."
fi
