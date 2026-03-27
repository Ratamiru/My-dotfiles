#!/usr/bin/env bash
# collect.sh — копирует конфиги с текущей машины в ~/dotfiles
# Запускать на исходной машине

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

echo "==> Сборка dotfiles в $DOTFILES_DIR"

# Функция копирования с исключением ненужного
copy_config() {
    local src="$1"
    local dst="$DOTFILES_DIR/$2"
    if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        if [ -d "$src" ]; then
            rsync -a --delete \
                --exclude='node_modules/' \
                --exclude='.cache/' \
                --exclude='__pycache__/' \
                --exclude='*.pyc' \
                --exclude='.git/' \
                "$src/" "$dst/"
        else
            cp -f "$src" "$dst"
        fi
        echo "  ✓ $2"
    else
        echo "  - пропущен (не найден): $2"
    fi
}

# --- Shell ---
copy_config "$HOME_DIR/.zshrc"            "home/.zshrc"
copy_config "$HOME_DIR/.p10k.zsh"         "home/.p10k.zsh"
copy_config "$HOME_DIR/.bash_profile"     "home/.bash_profile"
copy_config "$HOME_DIR/.bashrc"           "home/.bashrc"
copy_config "$HOME_DIR/.gtkrc-2.0"        "home/.gtkrc-2.0"
copy_config "$HOME_DIR/.gitconfig"        "home/.gitconfig"
copy_config "$HOME_DIR/.fonts.conf"       "home/.fonts.conf"

# --- Config dirs ---
copy_config "$HOME_DIR/.config/niri"       ".config/niri"
copy_config "$HOME_DIR/.config/fuzzel"     ".config/fuzzel"
copy_config "$HOME_DIR/.config/foot"       ".config/foot"
copy_config "$HOME_DIR/.config/kitty"      ".config/kitty"
copy_config "$HOME_DIR/.config/fish"       ".config/fish"
copy_config "$HOME_DIR/.config/starship.toml" ".config/starship.toml"
copy_config "$HOME_DIR/.config/gtk-3.0"    ".config/gtk-3.0"
copy_config "$HOME_DIR/.config/gtk-4.0"    ".config/gtk-4.0"
copy_config "$HOME_DIR/.config/quickshell" ".config/quickshell"
copy_config "$HOME_DIR/.config/hypr"       ".config/hypr"
copy_config "$HOME_DIR/.config/btop"       ".config/btop"
copy_config "$HOME_DIR/.config/nvim"       ".config/nvim"
copy_config "$HOME_DIR/.config/mpv"        ".config/mpv"
copy_config "$HOME_DIR/.config/git"        ".config/git"
copy_config "$HOME_DIR/.config/zshrc.d"    ".config/zshrc.d"
copy_config "$HOME_DIR/.config/cava"       ".config/cava"
copy_config "$HOME_DIR/.config/easyeffects" ".config/easyeffects"

# --- Noctalia (bar, notifs, wallpaper, lock, theming) ---
# colorschemes/ и colors.json исключены — они генерируются автоматически
copy_config "$HOME_DIR/.config/noctalia/settings.json" ".config/noctalia/settings.json"
copy_config "$HOME_DIR/.config/noctalia/plugins.json"  ".config/noctalia/plugins.json"

echo ""
echo "==> Готово! Проверь ~/dotfiles и инициализируй git:"
echo "    cd ~/dotfiles && git init && git add -A && git commit -m 'init dotfiles'"
