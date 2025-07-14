#!/bin/bash
# Package installation script for universal dotfiles

# Source environment detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-env.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Package lists by category
ESSENTIAL_PACKAGES=(
    "curl"
    "git"
    "vim"
    "unzip"
    "tar"
)

DEVELOPMENT_PACKAGES=(
    "fzf"
    "jq"
    "gh"
    "glow"
)

FULL_PACKAGES=(
    "htop"
    "tree"
    "wget"
    "rsync"
)

# Install packages based on package manager
install_package() {
    local package="$1"
    local package_manager="$2"
    
    case "$package_manager" in
        "apt")
            if ! dpkg -l | grep -q "^ii  $package "; then
                log "Installing $package with apt..."
                sudo apt-get update -qq && sudo apt-get install -y "$package"
            else
                log "Package $package already installed"
            fi
            ;;
        "apk")
            if ! apk info -e "$package" >/dev/null 2>&1; then
                log "Installing $package with apk..."
                sudo apk add "$package"
            else
                log "Package $package already installed"
            fi
            ;;
        "yum"|"dnf")
            if ! rpm -qa | grep -q "^$package"; then
                log "Installing $package with $package_manager..."
                sudo "$package_manager" install -y "$package"
            else
                log "Package $package already installed"
            fi
            ;;
        "pacman")
            if ! pacman -Q "$package" >/dev/null 2>&1; then
                log "Installing $package with pacman..."
                sudo pacman -S --noconfirm "$package"
            else
                log "Package $package already installed"
            fi
            ;;
        "zypper")
            if ! zypper se -i "$package" >/dev/null 2>&1; then
                log "Installing $package with zypper..."
                sudo zypper install -y "$package"
            else
                log "Package $package already installed"
            fi
            ;;
        "brew")
            if ! brew list "$package" >/dev/null 2>&1; then
                log "Installing $package with brew..."
                brew install "$package"
            else
                log "Package $package already installed"
            fi
            ;;
        *)
            log_warning "Unknown package manager: $package_manager. Skipping $package"
            ;;
    esac
}

# Install packages for specific distribution
install_packages_for_distro() {
    local packages=("$@")
    
    # Special handling for some packages
    for package in "${packages[@]}"; do
        case "$package" in
            "gh")
                install_github_cli
                ;;
            "glow")
                install_glow
                ;;
            "fzf")
                install_fzf
                ;;
            *)
                install_package "$package" "$DOTFILES_PACKAGE_MANAGER"
                ;;
        esac
    done
}

# Install GitHub CLI
install_github_cli() {
    if command -v gh >/dev/null 2>&1; then
        log "GitHub CLI already installed"
        return
    fi
    
    log "Installing GitHub CLI..."
    
    case "$DOTFILES_PACKAGE_MANAGER" in
        "apt")
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update -qq && sudo apt-get install -y gh
            ;;
        "apk")
            sudo apk add github-cli
            ;;
        "yum"|"dnf")
            sudo "$DOTFILES_PACKAGE_MANAGER" install -y 'dnf-command(config-manager)'
            sudo "$DOTFILES_PACKAGE_MANAGER" config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo "$DOTFILES_PACKAGE_MANAGER" install -y gh
            ;;
        "brew")
            brew install gh
            ;;
        *)
            log_warning "GitHub CLI installation not supported for $DOTFILES_PACKAGE_MANAGER"
            ;;
    esac
}

# Install Glow
install_glow() {
    if command -v glow >/dev/null 2>&1; then
        log "Glow already installed"
        return
    fi
    
    log "Installing Glow..."
    
    case "$DOTFILES_PACKAGE_MANAGER" in
        "apt")
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt-get update -qq && sudo apt-get install -y glow
            ;;
        "apk")
            sudo apk add glow
            ;;
        "yum"|"dnf")
            echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
            sudo "$DOTFILES_PACKAGE_MANAGER" install -y glow
            ;;
        "brew")
            brew install glow
            ;;
        *)
            log_warning "Glow installation not supported for $DOTFILES_PACKAGE_MANAGER"
            ;;
    esac
}

# Install FZF
install_fzf() {
    if command -v fzf >/dev/null 2>&1; then
        log "FZF already installed"
        return
    fi
    
    log "Installing FZF..."
    
    case "$DOTFILES_PACKAGE_MANAGER" in
        "apt")
            sudo apt-get update -qq && sudo apt-get install -y fzf
            ;;
        "apk")
            sudo apk add fzf
            ;;
        "yum"|"dnf")
            sudo "$DOTFILES_PACKAGE_MANAGER" install -y fzf
            ;;
        "pacman")
            sudo pacman -S --noconfirm fzf
            ;;
        "brew")
            brew install fzf
            ;;
        *)
            # Fallback to manual installation
            log "Installing FZF manually..."
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --all
            ;;
    esac
}

# Install UV (Python package manager)
install_uv() {
    if command -v uv >/dev/null 2>&1; then
        log "UV already installed"
        return
    fi
    
    log "Installing UV..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Add to PATH for current session
    if [[ -f "$HOME/.local/bin/uv" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

# Main installation function
install_packages() {
    local mode="$1"
    
    log "Installing packages for mode: $mode"
    
    # Always install essential packages
    log "Installing essential packages..."
    install_packages_for_distro "${ESSENTIAL_PACKAGES[@]}"
    
    # Install UV for Python management
    install_uv
    
    case "$mode" in
        "minimal")
            log "Minimal installation complete"
            ;;
        "development")
            log "Installing development packages..."
            install_packages_for_distro "${DEVELOPMENT_PACKAGES[@]}"
            ;;
        "full")
            log "Installing development packages..."
            install_packages_for_distro "${DEVELOPMENT_PACKAGES[@]}"
            log "Installing full packages..."
            install_packages_for_distro "${FULL_PACKAGES[@]}"
            ;;
        *)
            log_error "Unknown installation mode: $mode"
            exit 1
            ;;
    esac
    
    log_success "Package installation complete for mode: $mode"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_environment_all
    
    # Default to development mode if not specified
    mode="${1:-$DOTFILES_MODE}"
    [[ -z "$mode" ]] && mode="development"
    
    install_packages "$mode"
fi