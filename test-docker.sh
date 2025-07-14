#!/bin/bash
# Test script to verify dotfiles work in Docker containers

echo "🐳 Testing dotfiles in Docker containers..."

# Test Ubuntu container
echo "Testing Ubuntu container..."
docker run --rm -it ubuntu:22.04 bash -c "
    apt-get update -qq && apt-get install -y curl git
    curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --mode minimal --quiet --name 'Test User' --email 'test@example.com'
    echo 'Testing shell...'
    zsh -c 'echo \"Zsh works! Current user: \$USER\"'
"

# Test Alpine container  
echo "Testing Alpine container..."
docker run --rm -it alpine:latest sh -c "
    apk add --no-cache curl git bash
    curl -fsSL https://raw.githubusercontent.com/byronluk/dotfiles/main/install.sh | bash -s -- --mode minimal --quiet --name 'Test User' --email 'test@example.com'
    echo 'Testing shell...'
    zsh -c 'echo \"Zsh works! Current user: \$USER\"'
"

echo "✅ Docker tests complete"