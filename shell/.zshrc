# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Skip almost everything when not interactive (e.g., VS Code env probes)
[[ $- != *i* ]] && return

# If running inside a container/Dev Container, tone things down
if [[ -f "/.dockerenv" || -n "$VSCODE_IPC_HOOK_CLI" || -n "$REMOTE_CONTAINERS" ]]; then
  export ZSH_DISABLE_COMPFIX=true
  export DISABLE_AUTO_UPDATE=true
  export DOTFILES_DEVCONTAINER=1
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# Base plugins for all environments
plugins=(
  git
  docker
  python
  node
  npm
  brew
  z
  fzf
  sudo
  colored-man-pages
  command-not-found
  zsh-autosuggestions
  zsh-syntax-highlighting
  history-substring-search
)

# Add ssh-agent plugin only for local sessions (not SSH connections)
# SSH agent forwarding works better without the plugin in remote sessions
if [[ -z "$SSH_CONNECTION" ]]; then
  plugins+=(ssh-agent)
fi

# Agent detection - only activate minimal mode for actual agents  
if [[ -n "$npm_config_yes" ]] || [[ -n "$CI" ]] || [[ "$-" != *i* ]]; then
  export AGENT_MODE=true
else
  export AGENT_MODE=false
fi

if [[ "$AGENT_MODE" == "true" ]]; then
  POWERLEVEL9K_INSTANT_PROMPT=off
  # Disable complex prompt features for AI agents
  POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
  POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
  # Ensure non-interactive mode
  export DEBIAN_FRONTEND=noninteractive
  export NONINTERACTIVE=1
fi

# Set Oh My Zsh theme conditionally - disable for agents only
if [[ "$AGENT_MODE" == "true" ]]; then
  ZSH_THEME=""  # Disable Powerlevel10k for agents
else
  ZSH_THEME="powerlevel10k/powerlevel10k"
fi

source $ZSH/oh-my-zsh.sh

# User configuration

# FZF configuration - set base path for system installation
if [[ -d "/opt/homebrew/opt/fzf" ]]; then
  export FZF_BASE="/opt/homebrew/opt/fzf"
elif [[ -d "/usr/local/opt/fzf" ]]; then
  export FZF_BASE="/usr/local/opt/fzf"
elif [[ -d "/usr/share/fzf" ]]; then
  export FZF_BASE="/usr/share/fzf"
fi

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code'
fi

# Language environment
export LANG=en_US.UTF-8

# Later in your .zshrc - minimal prompt for agents
if [[ "$AGENT_MODE" == "true" ]]; then
  PROMPT='%n@%m:%~%# '
  RPROMPT=''
  unsetopt CORRECT
  unsetopt CORRECT_ALL
  setopt NO_BEEP
  setopt NO_HIST_BEEP  
  setopt NO_LIST_BEEP
  
  # Agent-friendly aliases to avoid interactive prompts
  alias rm='rm -f'
  alias cp='cp -f' 
  alias mv='mv -f'
  alias npm='npm --no-fund --no-audit'
  alias yarn='yarn --non-interactive'
  alias pip='pip --quiet'
  alias git='git -c advice.detachedHead=false'
else
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi

# Load local bin environment
if [[ -f "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi

# Load system-specific configurations
if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate'

# Docker aliases
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias drmi='docker rmi'
alias dstop='docker stop'
alias dstart='docker start'
alias dexec='docker exec -it'

# Dotfiles management
alias dotfiles="cd ~/.dotfiles && git status"
alias dotupdate="~/.dotfiles/update.sh"
alias dotcheck="~/.dotfiles/update.sh --check"

# DevContainer aliases
alias dcbuild='devcontainer build --workspace-folder .'
alias dcup='devcontainer up --workspace-folder .'
alias dcexec='devcontainer exec --workspace-folder .'

# Python aliases
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# UV aliases (if installed)
if command -v uv >/dev/null 2>&1; then
    alias uvs='uv sync'
    alias uvi='uv install'
    alias uvr='uv run'
    alias uvx='uv tool run'
fi

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_VERIFY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Disable bash completion conflicts
unset BASH_COMPLETION_COMPAT_DIR