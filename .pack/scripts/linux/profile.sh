# ==========================================
# Shokunin AI Ecosystem - Shell Profile
# Add to ~/.bashrc or ~/.zshrc:
#   source ~/.shokunin/scripts/linux/profile.sh
# ==========================================

export SHOKUNIN_HOME="$HOME/.shokunin"

# Aliases
alias gst="git status"
alias ga="git add -A"
alias gc="git commit -m"
alias gp="git push"
alias gl="git pull --ff-only"
alias gb="git branch"
alias gco="git checkout"
alias ni="npm install"
alias nrd="npm run dev"
alias nrb="npm run build"
alias nt="npm test"
alias dps="docker ps"
alias dlog="docker logs -f"
alias dstop="docker stop"
alias ll="ls -la"

# Utils
mkcd() { mkdir -p "$1" && cd "$1"; }

# Shokunin opencode wrapper
opencode() {
    local wrapper="$SHOKUNIN_HOME/scripts/linux/run-opencode.sh"
    if [ -f "$wrapper" ]; then
        bash "$wrapper" "$@"
    else
        command opencode "$@"
    fi
}

