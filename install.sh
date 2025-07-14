#!/bin/bash
# Universal dotfiles installation script
# Works across macOS, Linux, DevContainers, and Docker containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
DOTFILES_REPO="https://github.com/byronluk/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_MODE=""
DOTFILES_GIT_NAME=""
DOTFILES_GIT_EMAIL=""
DOTFILES_SKIP_PACKAGES="false"
DOTFILES_SKIP_SHELL="false"
DOTFILES_SKIP_GIT="false"
DOTFILES_QUIET="false"

# Logging functions
log() {
    [[ "$DOTFILES_QUIET" == "true" ]] && return
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

log_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Help function
show_help() {
    cat << EOF
Universal Dotfiles Installation Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -m, --mode MODE         Installation mode (minimal, development, full)
    -d, --dir DIR           Installation directory (default: $HOME/.dotfiles)
    -r, --repo URL          Git repository URL
    -n, --name NAME         Git user name
    -e, --email EMAIL       Git user email
    --skip-packages         Skip package installation
    --skip-shell            Skip shell setup
    --skip-git              Skip git configuration
    -q, --quiet             Suppress output

MODES:
    minimal       Essential shell config and git setup (default for CI/Docker)
    development   Full shell setup with tools (default for DevContainers)
    full          Complete environment setup (default for bare metal)

EXAMPLES:
    # Basic installation (auto-detects environment)
    $0

    # Install in development mode
    $0 --mode development

    # Install with custom git configuration
    $0 --name "John Doe" --email "john@example.com"

    # Install minimal configuration only
    $0 --mode minimal --skip-packages

ENVIRONMENT VARIABLES:
    DOTFILES_MODE           Override installation mode
    DOTFILES_GIT_NAME       Git user name
    DOTFILES_GIT_EMAIL      Git user email
    DOTFILES_SKIP_PACKAGES  Skip package installation
    DOTFILES_SKIP_SHELL     Skip shell setup
    DOTFILES_SKIP_GIT       Skip git configuration
    DOTFILES_QUIET          Suppress output

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -m|--mode)
                DOTFILES_MODE="$2"
                shift 2
                ;;
            -d|--dir)
                DOTFILES_DIR="$2"
                shift 2
                ;;
            -r|--repo)
                DOTFILES_REPO="$2"
                shift 2
                ;;
            -n|--name)
                DOTFILES_GIT_NAME="$2"
                shift 2
                ;;
            -e|--email)
                DOTFILES_GIT_EMAIL="$2"
                shift 2
                ;;
            --skip-packages)
                DOTFILES_SKIP_PACKAGES="true"
                shift
                ;;
            --skip-shell)
                DOTFILES_SKIP_SHELL="true"
                shift
                ;;
            --skip-git)
                DOTFILES_SKIP_GIT="true"
                shift
                ;;
            -q|--quiet)
                DOTFILES_QUIET="true"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Clone or update dotfiles repository
setup_dotfiles_repo() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        log "Dotfiles directory already exists, updating..."
        cd "$DOTFILES_DIR"
        git pull origin main
    else
        log "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        cd "$DOTFILES_DIR"
    fi
}

# Setup git configuration
setup_git_config() {
    if [[ "$DOTFILES_SKIP_GIT" == "true" ]]; then
        log "Skipping git configuration"
        return
    fi
    
    log "Setting up git configuration..."
    
    # Use provided values or prompt for them
    if [[ -z "$DOTFILES_GIT_NAME" ]]; then
        if [[ "$DOTFILES_QUIET" != "true" ]]; then
            read -p "Enter your git name: " DOTFILES_GIT_NAME
        else
            DOTFILES_GIT_NAME="User"
        fi
    fi
    
    if [[ -z "$DOTFILES_GIT_EMAIL" ]]; then
        if [[ "$DOTFILES_QUIET" != "true" ]]; then
            read -p "Enter your git email: " DOTFILES_GIT_EMAIL
        else
            DOTFILES_GIT_EMAIL="user@example.com"
        fi
    fi
    
    # Create git config from template
    sed -e "s/DOTFILES_GIT_NAME/$DOTFILES_GIT_NAME/g" \
        -e "s/DOTFILES_GIT_EMAIL/$DOTFILES_GIT_EMAIL/g" \
        "$DOTFILES_DIR/git/.gitconfig" > "$HOME/.gitconfig"
    
    # Copy global gitignore
    cp "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
    
    log_success "Git configuration complete"
}

# Setup SSH configuration
setup_ssh_config() {
    if [[ "$DOTFILES_SKIP_GIT" == "true" ]]; then
        return
    fi
    
    log "Setting up SSH configuration..."
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Copy SSH config if it doesn't exist
    if [[ ! -f "$HOME/.ssh/config" ]]; then
        cp "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
    else
        log_warning "SSH config already exists, skipping"
    fi
}

# Main installation function
main() {
    log_header "🚀 Universal Dotfiles Installation"
    
    # Parse command line arguments
    parse_args "$@"
    
    # Set up dotfiles directory
    if [[ "$SCRIPT_DIR" == "$DOTFILES_DIR" ]] || [[ "$SCRIPT_DIR" == *"/dotfiles" ]]; then
        log "Using local dotfiles directory: $SCRIPT_DIR"
        DOTFILES_DIR="$SCRIPT_DIR"
    else
        setup_dotfiles_repo
    fi
    
    # Source environment detection
    source "$DOTFILES_DIR/scripts/detect-env.sh"
    detect_environment_all
    
    # Override mode if specified
    if [[ -n "$DOTFILES_MODE" ]]; then
        export DOTFILES_MODE
    fi
    
    # Show environment information
    if [[ "$DOTFILES_QUIET" != "true" ]]; then
        print_detection_results
    fi
    
    log_header "📦 Installing packages"
    if [[ "$DOTFILES_SKIP_PACKAGES" == "true" ]]; then
        log "Skipping package installation"
    else
        "$DOTFILES_DIR/scripts/install-packages.sh" "$DOTFILES_MODE"
    fi
    
    log_header "🐚 Setting up shell"
    if [[ "$DOTFILES_SKIP_SHELL" == "true" ]]; then
        log "Skipping shell setup"
    else
        "$DOTFILES_DIR/scripts/setup-shell.sh" "$DOTFILES_MODE" "$DOTFILES_DIR"
    fi
    
    log_header "🔧 Configuring git and SSH"
    setup_git_config
    setup_ssh_config
    
    log_header "✅ Installation complete!"
    log_success "Dotfiles have been installed successfully!"
    
    # Show next steps
    if [[ "$DOTFILES_QUIET" != "true" ]]; then
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        
        if [[ "$DOTFILES_MODE" != "minimal" ]]; then
            echo -e "  1. ${YELLOW}Restart your terminal${NC} or run: ${GREEN}source ~/.zshrc${NC}"
            echo -e "  2. ${YELLOW}Configure Powerlevel10k${NC} by running: ${GREEN}p10k configure${NC}"
        else
            echo -e "  1. ${YELLOW}Restart your terminal${NC} or run: ${GREEN}source ~/.zshrc${NC}"
        fi
        
        echo -e "  3. ${YELLOW}Customize your setup${NC} by editing: ${GREEN}~/.zshrc.local${NC}"
        echo ""
        echo -e "${CYAN}Enjoy your new dotfiles setup! 🎉${NC}"
    fi
}

# Run main function
main "$@"