#!/bin/bash
# Shell setup script for universal dotfiles

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

# Install Zsh if not available
install_zsh() {
    if command -v zsh >/dev/null 2>&1; then
        log "Zsh already installed"
        return
    fi
    
    log "Installing Zsh..."
    
    case "$DOTFILES_PACKAGE_MANAGER" in
        "apt")
            sudo apt-get update -qq && sudo apt-get install -y zsh
            ;;
        "apk")
            sudo apk add zsh
            ;;
        "yum"|"dnf")
            sudo "$DOTFILES_PACKAGE_MANAGER" install -y zsh
            ;;
        "pacman")
            sudo pacman -S --noconfirm zsh
            ;;
        "zypper")
            sudo zypper install -y zsh
            ;;
        "brew")
            brew install zsh
            ;;
        *)
            log_error "Cannot install Zsh: unsupported package manager $DOTFILES_PACKAGE_MANAGER"
            exit 1
            ;;
    esac
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log "Oh My Zsh already installed"
        return
    fi
    
    log "Installing Oh My Zsh..."
    
    # Download and install Oh My Zsh
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    
    # Verify installation
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh My Zsh installed successfully"
    else
        log_error "Oh My Zsh installation failed"
        return 1
    fi
}

# Install Powerlevel10k theme
install_powerlevel10k() {
    local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    
    if [[ -d "$theme_dir" ]]; then
        log "Powerlevel10k already installed"
        return
    fi
    
    log "Installing Powerlevel10k to $theme_dir..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
    
    # Verify installation
    if [[ -d "$theme_dir" ]]; then
        log_success "Powerlevel10k installed successfully"
    else
        log_error "Powerlevel10k installation failed"
        return 1
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    log "Installing Zsh plugins to $custom_dir/plugins/"
    
    # zsh-autosuggestions
    if [[ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]]; then
        log "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/plugins/zsh-autosuggestions"
    else
        log "zsh-autosuggestions already installed"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$custom_dir/plugins/zsh-syntax-highlighting" ]]; then
        log "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/plugins/zsh-syntax-highlighting"
    else
        log "zsh-syntax-highlighting already installed"
    fi
    
    # history-substring-search
    if [[ ! -d "$custom_dir/plugins/history-substring-search" ]]; then
        log "Installing history-substring-search..."
        git clone https://github.com/zsh-users/zsh-history-substring-search "$custom_dir/plugins/history-substring-search"
    else
        log "history-substring-search already installed"
    fi
    
    # Verify plugins
    local plugins_count=$(ls -d "$custom_dir/plugins/"* 2>/dev/null | wc -l)
    if [[ $plugins_count -gt 1 ]]; then
        log_success "Zsh plugins installed successfully ($plugins_count plugins)"
    else
        log_error "Zsh plugins installation may have failed"
    fi
}

# Setup shell configuration files
setup_shell_configs() {
    local dotfiles_dir="$1"
    
    # Create backup of existing configs
    if [[ -f "$HOME/.zshrc" ]]; then
        log "Backing up existing .zshrc..."
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Copy shell configurations
    log "Setting up shell configurations..."
    
    # Copy .zshrc
    cp "$dotfiles_dir/shell/.zshrc" "$HOME/.zshrc"
    
    # Copy .p10k.zsh
    cp "$dotfiles_dir/shell/.p10k.zsh" "$HOME/.p10k.zsh"
    
    # Setup .local/bin directory and env script
    mkdir -p "$HOME/.local/bin"
    cp "$dotfiles_dir/bin/env" "$HOME/.local/bin/env"
    chmod +x "$HOME/.local/bin/env"
    
    # Create .zshrc.local for system-specific configurations
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        cat > "$HOME/.zshrc.local" << 'EOF'
# Local Zsh configuration
# This file is sourced by .zshrc and can contain system-specific settings

# Example: Add local aliases
# alias mycommand='echo "Hello from local config"'

# Example: Add local environment variables
# export MY_LOCAL_VAR="value"

# Example: Add local PATH entries
# export PATH="/usr/local/custom/bin:$PATH"
EOF
    fi
}

# Set Zsh as default shell
set_default_shell() {
    local zsh_path
    zsh_path=$(command -v zsh)
    
    if [[ -z "$zsh_path" ]]; then
        log_error "Zsh not found, cannot set as default shell"
        return 1
    fi
    
    # Check if zsh is already the default shell
    if [[ "$SHELL" == "$zsh_path" ]]; then
        log "Zsh is already the default shell"
        return
    fi
    
    # Check if we can change the shell
    if ! has_sudo && [[ "$DOTFILES_USER_CONTEXT" != "root" ]]; then
        log_warning "Cannot change default shell without sudo access"
        log_warning "You can change it manually with: chsh -s $zsh_path"
        return
    fi
    
    # Add zsh to /etc/shells if not already there
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        log "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    
    # Change default shell
    log "Setting Zsh as default shell..."
    if [[ "$DOTFILES_USER_CONTEXT" == "root" ]]; then
        chsh -s "$zsh_path"
    else
        chsh -s "$zsh_path" "$USER"
    fi
}


# Main setup function
setup_shell() {
    local dotfiles_dir="$1"
    
    log "Setting up shell package"
    
    install_zsh
    install_oh_my_zsh
    install_powerlevel10k
    install_zsh_plugins
    setup_shell_configs "$dotfiles_dir"
    
    # Try to set as default shell for non-container environments
    if ! is_docker && ! is_ci; then
        set_default_shell
    fi
    
    log_success "Shell setup complete"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_environment_all
    
    # Default dotfiles directory
    dotfiles_dir="${1:-$(dirname "$SCRIPT_DIR")}"
    
    setup_shell "$dotfiles_dir"
fi