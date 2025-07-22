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
                export DEBIAN_FRONTEND=noninteractive
                if ! sudo apt-get update -qq && sudo apt-get install -y -qq "$package"; then
                    log_error "Failed to install $package with apt"
                    return 1
                fi
            else
                log "Package $package already installed"
            fi
            ;;
        "apk")
            if ! apk info -e "$package" >/dev/null 2>&1; then
                log "Installing $package with apk..."
                if ! sudo apk add "$package"; then
                    log_error "Failed to install $package with apk"
                    return 1
                fi
            else
                log "Package $package already installed"
            fi
            ;;
        "yum"|"dnf")
            if ! rpm -qa | grep -q "^$package"; then
                log "Installing $package with $package_manager..."
                if ! sudo "$package_manager" install -y "$package"; then
                    log_error "Failed to install $package with $package_manager"
                    return 1
                fi
            else
                log "Package $package already installed"
            fi
            ;;
        "pacman")
            if ! pacman -Q "$package" >/dev/null 2>&1; then
                log "Installing $package with pacman..."
                if ! sudo pacman -S --noconfirm "$package"; then
                    log_error "Failed to install $package with pacman"
                    return 1
                fi
            else
                log "Package $package already installed"
            fi
            ;;
        "zypper")
            if ! zypper se -i "$package" >/dev/null 2>&1; then
                log "Installing $package with zypper..."
                if ! sudo zypper install -y "$package"; then
                    log_error "Failed to install $package with zypper"
                    return 1
                fi
            else
                log "Package $package already installed"
            fi
            ;;
        "brew")
            if ! brew list "$package" >/dev/null 2>&1; then
                log "Installing $package with brew..."
                if ! brew install "$package"; then
                    log_error "Failed to install $package with brew"
                    return 1
                fi
            else
                log "Package $package already installed"
            fi
            ;;
        *)
            log_warning "Unknown package manager: $package_manager. Skipping $package"
            return 1
            ;;
    esac
}

# Install packages for specific distribution
install_packages_for_distro() {
    local packages=("$@")
    local failed_packages=()
    
    # Special handling for some packages
    for package in "${packages[@]}"; do
        case "$package" in
            "gh")
                if ! install_github_cli; then
                    failed_packages+=("$package")
                fi
                ;;
            "glow")
                if ! install_glow; then
                    failed_packages+=("$package")
                fi
                ;;
            "fzf")
                if ! install_fzf; then
                    failed_packages+=("$package")
                fi
                ;;
            *)
                if ! install_package "$package" "$DOTFILES_PACKAGE_MANAGER"; then
                    failed_packages+=("$package")
                fi
                ;;
        esac
    done
    
    # Report failed packages
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warning "Failed to install packages: ${failed_packages[*]}"
        log_warning "Some packages failed to install, but continuing with setup..."
    fi
}

# Install GitHub CLI
install_github_cli() {
    if command -v gh >/dev/null 2>&1; then
        log "GitHub CLI already installed"
        return 0
    fi
    
    log "Installing GitHub CLI..."
    
    case "$DOTFILES_PACKAGE_MANAGER" in
        "apt")
            if ! curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; then
                log_error "Failed to add GitHub CLI key"
                return 1
            fi
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            if ! sudo apt-get update -qq && sudo apt-get install -y gh; then
                log_error "Failed to install GitHub CLI"
                return 1
            fi
            ;;
        "apk")
            if ! sudo apk add github-cli; then
                log_error "Failed to install GitHub CLI"
                return 1
            fi
            ;;
        "yum"|"dnf")
            if ! sudo "$DOTFILES_PACKAGE_MANAGER" install -y 'dnf-command(config-manager)'; then
                log_error "Failed to install config-manager"
                return 1
            fi
            if ! sudo "$DOTFILES_PACKAGE_MANAGER" config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo; then
                log_error "Failed to add GitHub CLI repo"
                return 1
            fi
            if ! sudo "$DOTFILES_PACKAGE_MANAGER" install -y gh; then
                log_error "Failed to install GitHub CLI"
                return 1
            fi
            ;;
        "brew")
            if ! brew install gh; then
                log_error "Failed to install GitHub CLI"
                return 1
            fi
            ;;
        *)
            log_warning "GitHub CLI installation not supported for $DOTFILES_PACKAGE_MANAGER"
            return 1
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
        return 0
    fi
    
    log "Installing FZF..."
    
    case "$DOTFILES_PACKAGE_MANAGER" in
        "apt")
            if ! sudo apt-get update -qq && sudo apt-get install -y fzf; then
                log_error "Failed to install FZF"
                return 1
            fi
            ;;
        "apk")
            if ! sudo apk add fzf; then
                log_error "Failed to install FZF"
                return 1
            fi
            ;;
        "yum"|"dnf")
            if ! sudo "$DOTFILES_PACKAGE_MANAGER" install -y fzf; then
                log_error "Failed to install FZF"
                return 1
            fi
            ;;
        "pacman")
            if ! sudo pacman -S --noconfirm fzf; then
                log_error "Failed to install FZF"
                return 1
            fi
            ;;
        "brew")
            if ! brew install fzf; then
                log_error "Failed to install FZF"
                return 1
            fi
            ;;
        *)
            # Fallback to manual installation
            log "Installing FZF manually..."
            if ! git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; then
                log_error "Failed to clone FZF repository"
                return 1
            fi
            if ! ~/.fzf/install --all; then
                log_error "Failed to install FZF manually"
                return 1
            fi
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
    local package="$1"
    
    log "Installing package: $package"
    
    case "$package" in
        "dev-tools")
            log "Installing essential packages..."
            install_packages_for_distro "${ESSENTIAL_PACKAGES[@]}"
            log "Installing development packages..."
            install_packages_for_distro "${DEVELOPMENT_PACKAGES[@]}"
            # Install UV for Python management
            install_uv
            ;;
        "system-tools")
            log "Installing system packages..."
            install_packages_for_distro "${FULL_PACKAGES[@]}"
            ;;
        *)
            log_error "Unknown package: $package"
            exit 1
            ;;
    esac
    
    log_success "Package installation complete for: $package"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_environment_all
    
    # Default to dev-tools package if not specified
    package="${1:-dev-tools}"
    
    install_packages "$package"
fi