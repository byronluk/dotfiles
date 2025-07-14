# Byron's Dotfiles

A universal dotfiles setup that works across macOS, Linux, DevContainers, and Docker containers.

## Features

- **Universal Installation**: Works on macOS, Ubuntu, Alpine, and other Linux distributions
- **Environment Detection**: Automatically detects DevContainer, Docker, or bare metal environments
- **Multiple Installation Modes**: Minimal, Development, and Full modes
- **Container-Optimized**: Special handling for Docker containers and DevContainers
- **Security-First**: Sanitized configs with template-based personalization

## Quick Start

```bash
# One-line installation
curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash

# Or clone and install manually
git clone https://github.com/byronluk/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

## Installation Modes

### Minimal Mode (Default for CI/Docker)
- Basic shell configuration
- Essential aliases and functions
- Git configuration
- Minimal prompt for performance

### Development Mode (Default for DevContainers)
- Full Zsh setup with Oh My Zsh
- Powerlevel10k theme
- Development tools and plugins
- Language-specific configurations

### Full Mode (Default for bare metal)
- Complete development environment
- All tools and utilities
- GUI applications (macOS only)
- Full customization

## What's Included

### Shell Configuration
- Zsh with Oh My Zsh
- Powerlevel10k theme (lean style)
- Essential plugins: autosuggestions, syntax highlighting, fzf, z
- Agent mode detection for CI environments
- Custom aliases and functions

### Development Tools
- Git configuration with sensible defaults
- SSH configuration
- fzf, gh, glow, jq, and other CLI tools
- uv package manager
- Language-specific tools (Python, Node.js, Go)

### Environment-Specific Features
- DevContainer integration
- Docker container support
- macOS-specific configurations
- Linux distribution detection

## Structure

```
dotfiles/
├── install.sh              # Main installation script
├── shell/                  # Shell configurations
├── git/                    # Git configurations
├── ssh/                    # SSH configurations
├── bin/                    # Custom scripts and utilities
└── scripts/                # Installation and setup scripts
```

## Environment Variables

- `DOTFILES_MODE`: Override installation mode (minimal, development, full)
- `DOTFILES_SKIP_PACKAGES`: Skip package installation
- `DOTFILES_SKIP_SHELL`: Skip shell setup
- `DOTFILES_QUIET`: Suppress output

## Contributing

This is a personal dotfiles repository, but feel free to use it as inspiration for your own setup.