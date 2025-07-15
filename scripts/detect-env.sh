#!/bin/bash
# Environment detection script for universal dotfiles installation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
DOTFILES_OS=""
DOTFILES_DISTRO=""
DOTFILES_PACKAGE_MANAGER=""
DOTFILES_ENVIRONMENT=""
DOTFILES_MODE=""
DOTFILES_USER_CONTEXT=""

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        DOTFILES_OS="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        DOTFILES_OS="Linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        DOTFILES_OS="Windows"
    else
        DOTFILES_OS="Unknown"
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ "$DOTFILES_OS" != "Linux" ]]; then
        return
    fi
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DOTFILES_DISTRO="$ID"
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        DOTFILES_DISTRO="$DISTRIB_ID"
    elif [[ -f /etc/debian_version ]]; then
        DOTFILES_DISTRO="debian"
    elif [[ -f /etc/redhat-release ]]; then
        DOTFILES_DISTRO="rhel"
    elif [[ -f /etc/arch-release ]]; then
        DOTFILES_DISTRO="arch"
    elif [[ -f /etc/alpine-release ]]; then
        DOTFILES_DISTRO="alpine"
    else
        DOTFILES_DISTRO="unknown"
    fi
}

# Detect package manager
detect_package_manager() {
    if [[ "$DOTFILES_OS" == "macOS" ]]; then
        if command -v brew >/dev/null 2>&1; then
            DOTFILES_PACKAGE_MANAGER="brew"
        else
            DOTFILES_PACKAGE_MANAGER="none"
        fi
    elif [[ "$DOTFILES_OS" == "Linux" ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            DOTFILES_PACKAGE_MANAGER="apt"
        elif command -v yum >/dev/null 2>&1; then
            DOTFILES_PACKAGE_MANAGER="yum"
        elif command -v dnf >/dev/null 2>&1; then
            DOTFILES_PACKAGE_MANAGER="dnf"
        elif command -v pacman >/dev/null 2>&1; then
            DOTFILES_PACKAGE_MANAGER="pacman"
        elif command -v zypper >/dev/null 2>&1; then
            DOTFILES_PACKAGE_MANAGER="zypper"
        elif command -v apk >/dev/null 2>&1; then
            DOTFILES_PACKAGE_MANAGER="apk"
        else
            DOTFILES_PACKAGE_MANAGER="unknown"
        fi
    else
        DOTFILES_PACKAGE_MANAGER="unknown"
    fi
}

# Detect environment context
detect_environment() {
    # Check for DevContainer
    if [[ -n "$REMOTE_CONTAINERS" ]] || [[ -n "$CODESPACES" ]] || [[ -f "/workspaces/.codespaces/shared/environment-variables" ]]; then
        DOTFILES_ENVIRONMENT="devcontainer"
    # Check for Docker container (during build or runtime)
    elif [[ -f /.dockerenv ]] || [[ -f /proc/1/cgroup ]] && grep -q docker /proc/1/cgroup 2>/dev/null; then
        # If we're in a DevContainer build context, prefer devcontainer mode
        if [[ -n "$DEBIAN_FRONTEND" ]] || [[ "$USER" == "vscode" ]] || [[ -d "/workspaces" ]] || [[ -d "/workspace" ]]; then
            DOTFILES_ENVIRONMENT="devcontainer"
        else
            DOTFILES_ENVIRONMENT="docker"
        fi
    # Check for CI environment
    elif [[ -n "$CI" ]] || [[ -n "$GITHUB_ACTIONS" ]] || [[ -n "$GITLAB_CI" ]] || [[ -n "$JENKINS_URL" ]] || [[ -n "$TRAVIS" ]]; then
        DOTFILES_ENVIRONMENT="ci"
    # Check for SSH session
    elif [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
        DOTFILES_ENVIRONMENT="ssh"
    # Default to bare metal
    else
        DOTFILES_ENVIRONMENT="bare-metal"
    fi
}

# Detect user context
detect_user_context() {
    if [[ $EUID -eq 0 ]]; then
        DOTFILES_USER_CONTEXT="root"
    elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        DOTFILES_USER_CONTEXT="sudo"
    else
        DOTFILES_USER_CONTEXT="user"
    fi
}

# Determine installation mode
determine_mode() {
    # Allow override via environment variable
    if [[ -n "$DOTFILES_MODE" ]]; then
        return
    fi
    
    case "$DOTFILES_ENVIRONMENT" in
        "devcontainer")
            DOTFILES_MODE="development"
            ;;
        "docker")
            DOTFILES_MODE="minimal"
            ;;
        "ci")
            DOTFILES_MODE="minimal"
            ;;
        "ssh")
            DOTFILES_MODE="development"
            ;;
        "bare-metal")
            DOTFILES_MODE="full"
            ;;
        *)
            DOTFILES_MODE="development"
            ;;
    esac
}

# Main detection function
detect_environment_all() {
    detect_os
    detect_distro
    detect_package_manager
    detect_environment
    detect_user_context
    determine_mode
}

# Print detection results
print_detection_results() {
    echo -e "${BLUE}Environment Detection Results:${NC}"
    echo -e "  OS: ${GREEN}$DOTFILES_OS${NC}"
    [[ -n "$DOTFILES_DISTRO" ]] && echo -e "  Distribution: ${GREEN}$DOTFILES_DISTRO${NC}"
    echo -e "  Package Manager: ${GREEN}$DOTFILES_PACKAGE_MANAGER${NC}"
    echo -e "  Environment: ${GREEN}$DOTFILES_ENVIRONMENT${NC}"
    echo -e "  User Context: ${GREEN}$DOTFILES_USER_CONTEXT${NC}"
    echo -e "  Installation Mode: ${GREEN}$DOTFILES_MODE${NC}"
    echo ""
}

# Check if specific environment
is_devcontainer() {
    [[ "$DOTFILES_ENVIRONMENT" == "devcontainer" ]]
}

is_docker() {
    [[ "$DOTFILES_ENVIRONMENT" == "docker" ]]
}

is_ci() {
    [[ "$DOTFILES_ENVIRONMENT" == "ci" ]]
}

is_ssh() {
    [[ "$DOTFILES_ENVIRONMENT" == "ssh" ]]
}

is_bare_metal() {
    [[ "$DOTFILES_ENVIRONMENT" == "bare-metal" ]]
}

is_macos() {
    [[ "$DOTFILES_OS" == "macOS" ]]
}

is_linux() {
    [[ "$DOTFILES_OS" == "Linux" ]]
}

has_sudo() {
    [[ "$DOTFILES_USER_CONTEXT" == "sudo" ]] || [[ "$DOTFILES_USER_CONTEXT" == "root" ]]
}

# Export functions for use in other scripts
export -f detect_environment_all
export -f print_detection_results
export -f is_devcontainer
export -f is_docker
export -f is_ci
export -f is_ssh
export -f is_bare_metal
export -f is_macos
export -f is_linux
export -f has_sudo

# Run detection if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_environment_all
    print_detection_results
fi