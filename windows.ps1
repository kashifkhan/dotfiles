# Windows Setup Script
# Inspired by ubuntu.sh but adapted for Windows PowerShell
# Run with elevated permissions (right-click PowerShell, Run as Administrator)

# Force use of TLS 1.2 for PowerShell downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Error handling
$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Windows Setup Script"

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) { Write-Output $args }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info($message) {
    Write-ColorOutput Green "INFO: $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "WARN: $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "ERROR: $message"
}

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator. Right-click PowerShell and select 'Run as Administrator'."
    exit 1
}

#-------------------------------------------------------------------------------
# 1. ENSURE WINGET IS AVAILABLE
#-------------------------------------------------------------------------------
Write-Info "Checking Windows Package Manager (winget) availability"

# Check winget availability (built into Windows 10+)
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "Winget not found. Installing App Installer from Microsoft Store..."
    Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
    Read-Host "Press Enter after installing App Installer from the Microsoft Store"
    
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "Winget is required but not available. Please install App Installer from the Microsoft Store and try again."
        exit 1
    }
}

Write-Info "Winget version: $(winget --version)"

#-------------------------------------------------------------------------------
# 2. GIT SETUP
#-------------------------------------------------------------------------------
Write-Info "Setting up Git and SSH/GPG keys"

# Ensure Git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Git..."
    winget install --id Git.Git -e --source winget
    # Update PATH without requiring restart
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Info "Git is already installed: $(git --version)"
}

# Configure Git
$fullName = Read-Host "Enter your full name for Git"
$email = Read-Host "Enter your email for Git"

git config --global user.name "$fullName"
git config --global user.email "$email"
git config --global alias.grum "rebase upstream main"
git config --global alias.gfu "fetch upstream"
git config --global alias.gsw "switch"
git config --global alias.gl "log"
git config --global alias.gar "remote add"
git config --global init.defaultBranch "main"
git config --global core.autocrlf true

# Set up SSH key for GitHub
$sshDir = "$env:USERPROFILE\.ssh"
$sshKey = "$sshDir\id_ed25519"

if (!(Test-Path $sshKey)) {
    Write-Info "Creating SSH directory if it doesn't exist..."
    if (!(Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir | Out-Null
    }
    
    Write-Info "Generating SSH key for GitHub..."
    ssh-keygen -t ed25519 -C "$email" -f $sshKey -N '""'
    
    # Ensure ssh-agent is running
    Start-Service ssh-agent -ErrorAction SilentlyContinue
    Set-Service ssh-agent -StartupType Automatic
    
    # Add SSH key to agent
    ssh-add $sshKey
    
    Write-Info "SSH key generated. Public key:"
    Get-Content "$sshKey.pub"
    Write-Info "Copy the above public key and add it to your GitHub account: https://github.com/settings/keys"
} else {
    Write-Info "SSH key already exists at $sshKey"
}

# Set up GPG for commit signing (need to install Gpg4win first)
if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Gpg4win..."
    winget install --id GnuPG.Gpg4win -e --source winget
    # Update PATH without requiring restart
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

if (Get-Command gpg -ErrorAction SilentlyContinue) {
    Write-Info "Setting up Git commit signing with GPG..."
    
    # Configure Git to sign commits
    git config --global commit.gpgsign true
    git config --global gpg.program "$(where.exe gpg)"
    
    # Check for existing GPG key
    $hasGpgKey = $false
    $gpgOutput = gpg --list-secret-keys --keyid-format=long 2>$null
    if ($gpgOutput -match "sec") {
        $hasGpgKey = $true
    }
    
    if (-not $hasGpgKey) {
        Write-Info "No GPG key found. Generating a new GPG key..."
        
        # Create a batch file for key generation
        $batchFile = "$env:TEMP\gpg-batch"
        @"
%echo Generating GPG key for Git commit signing
Key-Type: RSA
Key-Length: 4096
Name-Real: $fullName
Name-Email: $email
Expire-Date: 0
%no-protection
%commit
%echo Done
"@ | Out-File -FilePath $batchFile -Encoding ASCII
        
        # Generate the key in batch mode
        gpg --batch --generate-key $batchFile
        Remove-Item $batchFile -Force
        
        # Get the key ID and configure Git
        $keyId = (gpg --list-secret-keys --keyid-format=long | Select-String -Pattern "[0-9A-F]{16}" | Select-Object -First 1).Matches.Value
        if ($keyId) {
            git config --global user.signingkey $keyId
            Write-Info "GPG key generated and configured in Git."
            Write-Info "Your GPG key ID: $keyId"
            
            # Export public key for GitHub
            Write-Info "Your GPG public key (add to GitHub at https://github.com/settings/keys):"
            gpg --armor --export $keyId
        } else {
            Write-Warning "GPG key was generated but could not extract key ID. Please set manually."
        }
    } else {
        Write-Info "Existing GPG key found. To use it for Git, run:"
        Write-Info "      gpg --list-secret-keys --keyid-format=long"
        Write-Info "      git config --global user.signingkey YOUR_KEY_ID"
    }
}

#-------------------------------------------------------------------------------
# 3. DEV ENVIRONMENT SETUP
#-------------------------------------------------------------------------------
Write-Info "Setting up development environment"

# Install Node.js LTS
Write-Info "Installing Node.js LTS..."
winget install --id OpenJS.NodeJS.LTS -e --source winget
# Update PATH without requiring restart
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#-------------------------------------------------------------------------------
# 4. WSL UBUNTU SETUP
#-------------------------------------------------------------------------------
Write-Info "Setting up WSL with Ubuntu..."

# Check if WSL is already installed
$wslInstalled = $false
try {
    $wslCheck = wsl --status 2>&1
    if ($wslCheck -notlike "*WSL*not*installed*") {
        $wslInstalled = $true
        Write-Info "WSL is already installed"
    }
} catch {
    $wslInstalled = $false
}

if (-not $wslInstalled) {
    Write-Info "Installing WSL..."
    # Enable the WSL feature
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    
    # Enable Virtual Machine Platform feature required for WSL 2
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    Write-Warning "WSL features have been enabled. A system restart may be required before continuing."
    $restartChoice = Read-Host "Would you like to restart now? (y/n)"
    if ($restartChoice -eq "y") {
        Restart-Computer -Force
        exit
    } else {
        Write-Warning "Continuing without restart, but WSL installation may not complete properly."
    }
}

# Install WSL with Ubuntu as the default distribution
Write-Info "Installing Ubuntu on WSL..."
wsl --install -d Ubuntu

Write-Info "WSL Ubuntu setup complete. You can launch Ubuntu by typing 'wsl' or 'ubuntu' in a command prompt."
Write-Info "When Ubuntu first launches, you'll need to create a username and password."

#-------------------------------------------------------------------------------
# 5. DESKTOP APPLICATIONS
#-------------------------------------------------------------------------------
Write-Info "Installing desktop applications..."

# Common developer tools
Write-Info "Installing development tools..."
winget install --id Microsoft.VisualStudioCode -e --source winget
winget install --id Docker.DockerDesktop -e --source winget
winget install --id Microsoft.PowerToys -e --source winget

# Web browsers
Write-Info "Installing web browsers..."
winget install --id Google.Chrome.Beta -e --source winget
winget install --id Microsoft.Edge -e --source winget
winget install --id Mozilla.Firefox -e --source winget

# Communication
Write-Info "Installing communication tools..."
winget install --id OpenWhisperSystems.Signal -e --source winget
winget install --id WhatsApp.WhatsApp -e --source winget

# Utilities
Write-Info "Installing utilities..."
winget install --id VideoLAN.VLC -e --source winget
winget install --id qBittorrent.qBittorrent -e --source winget
winget install --id WiresharkFoundation.Wireshark -e --source winget
winget install --id Cryptomator.Cryptomator -e --source winget
winget install --id tailscale.tailscale -e --source winget
winget install --id MullvadVPN.MullvadVPN -e --source winget

#-------------------------------------------------------------------------------
# 6. WINDOWS TERMINAL SETUP
#-------------------------------------------------------------------------------
Write-Info "Setting up Windows Terminal..."

#-------------------------------------------------------------------------------
# 7. FINISH
#-------------------------------------------------------------------------------
Write-Info "Setup complete! Some changes may require restarting your computer."
Write-Info "Remember to add your SSH and GPG keys to GitHub."
