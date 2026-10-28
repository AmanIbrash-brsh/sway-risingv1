# sway-rising zsh config (installed only when you have no ~/.zshrc)
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

export PATH="$HOME/.local/bin:$PATH"

# Aliases and tool hooks (fzf, zoxide, eza) live in ~/.oh-my-zsh/custom/sysadmin.zsh

# nvm (optional)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
