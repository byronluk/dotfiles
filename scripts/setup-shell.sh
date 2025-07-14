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
}

# Install Powerlevel10k theme
install_powerlevel10k() {
    local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    
    if [[ -d "$theme_dir" ]]; then
        log "Powerlevel10k already installed"
        return
    fi
    
    log "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
}

# Install Zsh plugins
install_zsh_plugins() {
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # zsh-autosuggestions
    if [[ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]]; then
        log "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/plugins/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$custom_dir/plugins/zsh-syntax-highlighting" ]]; then
        log "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/plugins/zsh-syntax-highlighting"
    fi
    
    # history-substring-search
    if [[ ! -d "$custom_dir/plugins/history-substring-search" ]]; then
        log "Installing history-substring-search..."
        git clone https://github.com/zsh-users/zsh-history-substring-search "$custom_dir/plugins/history-substring-search"
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
    
    # Copy .p10k.zsh only for non-minimal modes
    if [[ "$DOTFILES_MODE" != "minimal" ]]; then
        cp "$dotfiles_dir/shell/.p10k.zsh" "$HOME/.p10k.zsh"
    fi
    
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

# Create minimal shell setup for CI/Docker environments
setup_minimal_shell() {
    local dotfiles_dir="$1"
    
    log "Setting up minimal shell configuration..."
    
    # Create a minimal .zshrc
    cat > "$HOME/.zshrc" << 'EOF'
# Minimal Zsh configuration for containers/CI
export HISTFILE=~/.zsh_history
export HISTSIZE=1000
export SAVEHIST=1000

# Basic options
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt AUTO_CD
setopt AUTO_PUSHD

# Simple prompt
PROMPT='%n@%m:%~%# '

# Basic aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# Agent-friendly aliases
alias rm='rm -f'
alias cp='cp -f'
alias mv='mv -f'
alias pip='pip --quiet'
alias git='git -c advice.detachedHead=false'

# Load local configurations
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
EOF
    
    # Setup PATH management
    mkdir -p "$HOME/.local/bin"
    cp "$dotfiles_dir/bin/env" "$HOME/.local/bin/env"
    chmod +x "$HOME/.local/bin/env"
    
    # Create minimal local config
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        echo "# Local Zsh configuration for container" > "$HOME/.zshrc.local"
    fi
}

# Main setup function
setup_shell() {
    local mode="$1"
    local dotfiles_dir="$2"
    
    log "Setting up shell for mode: $mode"
    
    case "$mode" in
        "minimal")
            install_zsh
            setup_minimal_shell "$dotfiles_dir"
            ;;
        "development"|"full")
            install_zsh
            install_oh_my_zsh
            install_powerlevel10k
            install_zsh_plugins
            setup_shell_configs "$dotfiles_dir"
            ;;
        *)
            log_error "Unknown shell setup mode: $mode"
            exit 1
            ;;
    esac
    
    # Try to set as default shell for non-container environments
    if ! is_docker && ! is_ci; then
        set_default_shell
    fi
    
    log_success "Shell setup complete for mode: $mode"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_environment_all
    
    # Default to development mode if not specified
    mode="${1:-$DOTFILES_MODE}"
    [[ -z "$mode" ]] && mode="development"
    
    # Default dotfiles directory
    dotfiles_dir="${2:-$(dirname "$SCRIPT_DIR")}"
    
    setup_shell "$mode" "$dotfiles_dir"
fi