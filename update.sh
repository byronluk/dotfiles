#!/bin/bash
# Update dotfiles to latest version

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default dotfiles directory
DOTFILES_DIR="$HOME/.dotfiles"

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

# Show help
show_help() {
    cat << EOF
Dotfiles Update Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -d, --dir DIR   Dotfiles directory (default: $HOME/.dotfiles)
    --check         Check for updates without applying them
    --force         Force update even if no changes detected

EXAMPLES:
    # Update dotfiles to latest version
    $0

    # Check for updates without applying them
    $0 --check

    # Force update
    $0 --force

EOF
}

# Check if dotfiles directory exists
check_dotfiles_dir() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        log_error "Please run the dotfiles installer first"
        exit 1
    fi
    
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        log_error "Dotfiles directory is not a git repository: $DOTFILES_DIR"
        log_error "Please reinstall dotfiles or manually fix the repository"
        exit 1
    fi
}

# Check for updates
check_updates() {
    log "Checking for updates..."
    
    cd "$DOTFILES_DIR"
    
    # Fetch latest changes
    if ! git fetch origin main; then
        log_error "Failed to fetch updates from remote repository"
        exit 1
    fi
    
    # Check if there are updates
    local current_hash=$(git rev-parse HEAD)
    local remote_hash=$(git rev-parse origin/main)
    
    if [[ "$current_hash" == "$remote_hash" ]]; then
        log_success "Dotfiles are already up to date"
        return 1
    fi
    
    # Show what will be updated
    log "Updates available:"
    git log --oneline HEAD..origin/main
    
    return 0
}

# Update dotfiles
update_dotfiles() {
    log "Updating dotfiles..."
    
    cd "$DOTFILES_DIR"
    
    # Stash any local changes
    if git status --porcelain | grep -q .; then
        log_warning "Local changes detected, stashing..."
        git stash push -m "Auto-stash before dotfiles update $(date)"
    fi
    
    # Pull latest changes
    if ! git pull origin main; then
        log_error "Failed to pull updates"
        exit 1
    fi
    
    log_success "Dotfiles updated successfully"
}

# Reinstall dotfiles
reinstall_dotfiles() {
    log "Reinstalling dotfiles..."
    
    # Run the installation script with full setup
    "$DOTFILES_DIR/install.sh" --mode full --quiet
    
    log_success "Dotfiles reinstalled successfully"
}

# Main function
main() {
    local check_only=false
    local force_update=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dir)
                DOTFILES_DIR="$2"
                shift 2
                ;;
            --check)
                check_only=true
                shift
                ;;
            --force)
                force_update=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check if dotfiles directory exists
    check_dotfiles_dir
    
    # Check for updates
    if check_updates; then
        # Updates available
        if [[ "$check_only" == "true" ]]; then
            log "Updates are available. Run without --check to apply them."
            exit 0
        fi
        
        # Update dotfiles
        update_dotfiles
        
        # Reinstall to apply changes
        reinstall_dotfiles
        
        log_success "🎉 Dotfiles update complete!"
        log "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
        
    elif [[ "$force_update" == "true" ]]; then
        # Force reinstall
        log "Force reinstalling dotfiles..."
        reinstall_dotfiles
        log_success "🎉 Dotfiles reinstall complete!"
        
    else
        # No updates available
        if [[ "$check_only" != "true" ]]; then
            log_success "No updates needed"
        fi
    fi
}

# Run main function
main "$@"