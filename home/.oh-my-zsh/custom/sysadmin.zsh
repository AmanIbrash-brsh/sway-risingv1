# Sysadmin helpers. Tools that are not installed are skipped silently.

# --- systemd / logs / network ---
alias sc='systemctl'
alias scu='systemctl --user'
alias jc='journalctl'
alias jcf='journalctl -f'
alias jce='journalctl -p err -b'          # errors since boot
alias ports='ss -tulpn'                   # listening sockets
alias myip='curl -s ifconfig.me; echo'
alias df='df -hT -x tmpfs -x devtmpfs'
alias free='free -h'
alias dnfu='sudo dnf upgrade --refresh'

# --- safer defaults ---
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# --- nicer replacements, enabled when installed ---
if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lah --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons'
else
    alias ll='ls -lah --color=auto'
fi
command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
if command -v fzf >/dev/null; then
    for f in /usr/share/fzf/shell/key-bindings.zsh /usr/share/fzf/shell/completion.zsh; do [ -r "$f" ] && source "$f"; done
    export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --color=bg+:#3b4261,fg+:#c0caf5,hl:#bb9af7,hl+:#bb9af7,pointer:#ff9e64,prompt:#7dcfff'
fi

# --- tmux: attach to "main" or create it ---
tm() { tmux new-session -A -s "${1:-main}"; }
