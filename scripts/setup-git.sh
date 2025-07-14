#!/bin/bash
# Git configuration setup

setup_git() {
    echo "Setting up git configuration..."
    
    # Use provided name and email or defaults
    local git_name="${DOTFILES_GIT_NAME:-Byron Luk}"
    local git_email="${DOTFILES_GIT_EMAIL:-byronluk@gmail.com}"
    
    # Configure git
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    # Copy gitconfig if it exists
    if [[ -f "$DOTFILES_DIR/git/.gitconfig" ]]; then
        cp "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
        
        # Replace placeholders with actual values
        sed -i.bak "s/YOUR_NAME/$git_name/g" "$HOME/.gitconfig"
        sed -i.bak "s/YOUR_EMAIL/$git_email/g" "$HOME/.gitconfig"
        rm "$HOME/.gitconfig.bak"
    fi
    
    # Handle SSH configuration in DevContainers
    if [[ -n "$REMOTE_CONTAINERS" ]] || [[ -n "$CODESPACES" ]]; then
        echo "Configuring SSH for DevContainer environment..."
        
        # Ensure SSH directory exists
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        
        # Create SSH config for DevContainer
        cat > "$HOME/.ssh/config" << 'EOF'
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_rsa
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
        chmod 600 "$HOME/.ssh/config"
        
        # Check if SSH agent is available
        if [[ -n "$SSH_AUTH_SOCK" ]] && [[ -S "$SSH_AUTH_SOCK" ]]; then
            echo "SSH agent detected - git operations should work"
        else
            echo "⚠️  SSH agent not available - git operations may require credentials"
        fi
    fi
    
    echo "Git configuration complete"
}