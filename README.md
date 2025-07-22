# 🏠 Byron's Universal Dotfiles

A comprehensive, cross-platform dotfiles setup that works seamlessly across macOS, Linux, DevContainers, and Docker containers.

## 🚀 Quick Start

```bash
# Install dotfiles (auto-detects environment)
curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash

# Or with custom configuration
curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --name "Your Name" --email "your.email@example.com"
```

## 📋 Features

### 🌍 **Universal Compatibility**
- **macOS**: Full native support with Homebrew
- **Linux**: Supports apt, yum/dnf, pacman, zypper, apk
- **DevContainers**: Optimized for VS Code development containers
- **Docker**: Works in any Docker container environment

### 🐚 **Shell Configuration**
- **Zsh** with Oh My Zsh and Powerlevel10k theme
- **Smart agent detection** for CI/non-interactive environments
- **Comprehensive aliases** for Git, Docker, and common commands
- **FZF integration** for fuzzy finding
- **Syntax highlighting** and **autosuggestions**

### 🔧 **Developer Tools**
- **Git** configuration with smart SSH handling
- **GitHub CLI** (gh) installation and setup
- **Modern tools**: fzf, jq, glow, tree, htop
- **Python management** with UV package manager
- **SSH agent forwarding** for DevContainers

### 🎯 **Installation Options**
- **Package-based**: Select specific packages (shell, dev-tools, system-tools, git-config, ssh-config)
- **Minimal**: Essential packages without git/SSH (shell + dev-tools + system-tools)
- **Full**: Complete environment with all packages (includes git/SSH configuration)

## 🛠️ Installation Options

### Basic Installation
```bash
# Auto-detect environment and install
curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash
```

### Custom Installation
```bash
# Install specific packages (Genesis containers)
curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --packages shell,dev-tools

# Install full setup with custom git configuration
curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --mode full --name "Your Name" --email "your.email@example.com"

# Install minimal setup (everything except git/SSH)
curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --mode minimal

# Quiet installation (for automation)
curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --packages shell,dev-tools --quiet
```

### Manual Installation
```bash
# Clone repository
git clone https://github.com/byronluk/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run installer
./install.sh --mode full
```

## 🔄 Update Management

### **Update Commands** (Custom to this setup)
```bash
# Check for updates
dotcheck

# Update to latest version
dotupdate

# Force reinstall
dotupdate --force

# Update with options
~/.dotfiles/update.sh --check    # Check only
~/.dotfiles/update.sh --force    # Force update
```

### **Dotfiles Management**
```bash
# Navigate to dotfiles directory and check status
dotfiles

# Manual update
cd ~/.dotfiles
git pull origin main
./install.sh --mode full --quiet
```

## 📚 Command Reference

### Installation Script Options
```bash
./install.sh [OPTIONS]

OPTIONS:
    -h, --help              Show help message
    -m, --mode MODE         Installation mode (minimal, full)
    -p, --packages LIST     Comma-separated list of packages to install
    -d, --dir DIR           Installation directory (default: ~/.dotfiles)
    -r, --repo URL          Git repository URL
    -n, --name NAME         Git user name
    -e, --email EMAIL       Git user email
    -q, --quiet             Suppress output

PACKAGES:
    shell         zsh + Oh My Zsh + Powerlevel10k + plugins
    dev-tools     fzf, glow, jq, gh, uv
    system-tools  htop, tree, wget, rsync
    git-config    Git configuration
    ssh-config    SSH configuration
```

### Update Script Options
```bash
./update.sh [OPTIONS]

OPTIONS:
    -h, --help      Show help message
    -d, --dir DIR   Dotfiles directory (default: ~/.dotfiles)
    --check         Check for updates without applying them
    --force         Force update even if no changes detected
```

## 🔧 Environment Variables

You can customize the installation using environment variables:

```bash
export DOTFILES_MODE=full
export DOTFILES_PACKAGES="shell,dev-tools,git-config"
export DOTFILES_GIT_NAME="Your Name"
export DOTFILES_GIT_EMAIL="your.email@example.com"
export DOTFILES_QUIET=true
```

## 🎨 Customization

### Local Customization
Create `~/.zshrc.local` for personal customizations that won't be overwritten:

```bash
# ~/.zshrc.local
export CUSTOM_VAR="value"
alias myalias="command"
```

### DevContainer Integration
Add to your `devcontainer.json`:

```json
{
  "postCreateCommand": "curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --mode full --quiet",
  "remoteEnv": {
    "SSH_AUTH_SOCK": "/tmp/ssh-agent.sock"
  },
  "mounts": [
    "source=${env:SSH_AUTH_SOCK},target=/tmp/ssh-agent.sock,type=bind"
  ]
}
```

## 🔐 Security

### SSH Agent Forwarding
The setup includes SSH agent forwarding for DevContainers:
- Automatically configures SSH for container environments
- Enables seamless git operations with your host SSH keys
- No need to copy private keys into containers

### Safe for Public Use
This repository contains no sensitive information:
- No private keys or credentials
- Uses template-based configuration
- Proper `.gitignore` for sensitive files
- Environment variable-based customization

## 🐳 Docker Usage

### Test in Docker
```bash
# Test Ubuntu container with Genesis setup
docker run -it ubuntu:22.04 bash -c "
    apt-get update && apt-get install -y curl git
    curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --packages shell,dev-tools --quiet
    zsh
"

# Test Alpine container with minimal setup
docker run -it alpine:latest sh -c "
    apk add --no-cache curl git bash
    curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --mode minimal --quiet
    zsh
"
```

## 🎯 Package-Based Installation System

### **Individual Packages**
- **shell**: zsh + Oh My Zsh + Powerlevel10k + plugins
- **dev-tools**: fzf, glow, jq, gh, uv (essential development tools)
- **system-tools**: htop, tree, wget, rsync (system utilities)
- **git-config**: Git user configuration and SSH setup
- **ssh-config**: SSH agent forwarding and key management

### **Package Groups**
- **Minimal Mode**: shell + dev-tools + system-tools (everything except git/SSH)
- **Full Mode**: All packages (shell + dev-tools + system-tools + git-config + ssh-config)

### **Usage Examples**
```bash
# Genesis containers (CLI tools only)
--packages shell,dev-tools

# DevContainers (full development setup)
--mode full

# Custom selection
--packages shell,dev-tools,git-config

# CI/CD environments
--packages shell
```

## 🧪 Testing

Run the test script to verify functionality:
```bash
./test-docker.sh
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test across different environments
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) for the excellent Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) for the beautiful prompt
- [DevContainers](https://containers.dev/) for the development container specification

---

**Note**: The `dotcheck` and `dotupdate` commands are specific to this dotfiles setup and provide convenient shortcuts for managing updates. Most dotfiles repositories don't include these features.