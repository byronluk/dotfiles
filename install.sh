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
DOTFILES_PACKAGES=""
DOTFILES_GIT_NAME=""
DOTFILES_GIT_EMAIL=""
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
    -m, --mode MODE         Installation mode (minimal, full)
    -p, --packages LIST     Comma-separated list of packages to install
    -d, --dir DIR           Installation directory (default: $HOME/.dotfiles)
    -r, --repo URL          Git repository URL
    -n, --name NAME         Git user name
    -e, --email EMAIL       Git user email
    -q, --quiet             Suppress output

MODES:
    minimal       shell + dev-tools + system-tools
    full          shell + dev-tools + system-tools + git-config + ssh-config

PACKAGES:
    shell         zsh + Oh My Zsh + Powerlevel10k + plugins
    dev-tools     fzf, glow, jq, gh, uv
    system-tools  htop, tree, wget, rsync
    git-config    Git configuration
    ssh-config    SSH configuration

EXAMPLES:
    # Install minimal setup (everything except git/SSH)
    $0 --mode minimal

    # Install full setup
    $0 --mode full

    # Install specific packages
    $0 --packages shell,dev-tools

    # Genesis container setup
    $0 --packages shell,dev-tools

    # Custom git configuration
    $0 --mode full --name "John Doe" --email "john@example.com"

ENVIRONMENT VARIABLES:
    DOTFILES_MODE           Override installation mode
    DOTFILES_PACKAGES       Override package selection
    DOTFILES_GIT_NAME       Git user name
    DOTFILES_GIT_EMAIL      Git user email
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
            -p|--packages)
                DOTFILES_PACKAGES="$2"
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
        # Ensure proper ownership in container environments
        if [[ "$USER" != "root" ]]; then
            chown -R "$USER:$USER" "$DOTFILES_DIR" 2>/dev/null || true
        fi
    fi
}

# Determine packages to install
determine_packages() {
    # If packages explicitly specified, use them
    if [[ -n "$DOTFILES_PACKAGES" ]]; then
        return
    fi
    
    # If mode specified, convert to packages
    case "$DOTFILES_MODE" in
        "minimal")
            DOTFILES_PACKAGES="shell,dev-tools,system-tools"
            ;;
        "full")
            DOTFILES_PACKAGES="shell,dev-tools,system-tools,git-config,ssh-config"
            ;;
        "")
            # Auto-detect based on environment
            case "$DOTFILES_ENVIRONMENT" in
                "devcontainer"|"docker")
                    DOTFILES_PACKAGES="shell,dev-tools,system-tools"
                    ;;
                "ci")
                    DOTFILES_PACKAGES="shell"
                    ;;
                *)
                    DOTFILES_PACKAGES="shell,dev-tools,system-tools,git-config,ssh-config"
                    ;;
            esac
            ;;
        *)
            log_error "Unknown mode: $DOTFILES_MODE"
            exit 1
            ;;
    esac
    
    export DOTFILES_PACKAGES
}

# Setup git configuration
setup_git_config() {
    
    # Use provided values or prompt for them
    if [[ -z "$DOTFILES_GIT_NAME" ]]; then
        if [[ "$DOTFILES_QUIET" != "true" ]]; then
            read -p "Enter your git name: " DOTFILES_GIT_NAME
        else
            DOTFILES_GIT_NAME="Byron Luk"
        fi
    fi
    
    if [[ -z "$DOTFILES_GIT_EMAIL" ]]; then
        if [[ "$DOTFILES_QUIET" != "true" ]]; then
            read -p "Enter your git email: " DOTFILES_GIT_EMAIL
        else
            DOTFILES_GIT_EMAIL="byronluk@gmail.com"
        fi
    fi
    
    # Export variables for setup script
    export DOTFILES_GIT_NAME
    export DOTFILES_GIT_EMAIL
    
    # Use dedicated git setup script
    source "$DOTFILES_DIR/scripts/setup-git.sh"
    setup_git
}

# Setup SSH configuration
setup_ssh_config() {
    
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
    
    # Determine which packages to install
    determine_packages
    
    log "Installing packages: $DOTFILES_PACKAGES"
    
    # Convert comma-separated packages to array
    IFS=',' read -ra PACKAGE_ARRAY <<< "$DOTFILES_PACKAGES"
    
    # Install each package
    for package in "${PACKAGE_ARRAY[@]}"; do
        case "$package" in
            "shell")
                log_header "🐚 Setting up shell"
                "$DOTFILES_DIR/scripts/setup-shell.sh" "$DOTFILES_DIR"
                ;;
            "dev-tools"|"system-tools")
                log_header "📦 Installing $package"
                "$DOTFILES_DIR/scripts/install-packages.sh" "$package"
                ;;
            "git-config")
                log_header "🔧 Configuring git"
                setup_git_config
                ;;
            "ssh-config")
                log_header "🔑 Configuring SSH"
                setup_ssh_config
                ;;
            *)
                log_error "Unknown package: $package"
                ;;
        esac
    done
    
    log_header "✅ Installation complete!"
    log_success "Dotfiles have been installed successfully!"
    
    # Show next steps
    if [[ "$DOTFILES_QUIET" != "true" ]]; then
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        
        # Check if shell package was installed
        if [[ "$DOTFILES_PACKAGES" == *"shell"* ]]; then
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