# Shell
autoload -Uz compinit && compinit
setopt AUTO_CD HIST_IGNORE_ALL_DUPS

# Tools
eval "$(starship init zsh)"
eval "$(mise activate zsh)"

# PATH: one entry, no repeats
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias ls='eza --icons=always'
alias ll='eza -l --icons=always'
alias la='eza -la --icons=always'
alias grep='rg'
