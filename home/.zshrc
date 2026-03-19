# Enable Powerlevel10k instant prompt (must be at the very top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Local bin
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git                      # алиасы для git
  sudo                     # ESC ESC - добавляет sudo к команде
  zsh-autosuggestions      # подсказки из истории (серым текстом)
  zsh-syntax-highlighting  # подсветка команд
  fzf                      # fuzzy поиск
)

source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# nvim с Godot LSP сервером
alias gvim='nvim --listen /tmp/godot-nvim'

# opencode
export PATH=/home/ratamiru/.opencode/bin:$PATH
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# SSH agent
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > ~/.ssh/agent.env
fi
if [[ ! -f ~/.ssh/agent.env ]]; then
    ssh-agent -t 1h > ~/.ssh/agent.env
fi
source ~/.ssh/agent.env > /dev/null
ssh-add -l > /dev/null 2>&1 || {
    ssh-add ~/.ssh/id_ed25519_github1
    ssh-add ~/.ssh/id_ed25519_github2
}
