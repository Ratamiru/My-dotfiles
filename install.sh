#!/usr/bin/env bash
# install.sh — устанавливает dotfiles на новой машине через симлинки
# Запускать на целевой машине (ноут)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

echo "==> Установка dotfiles из $DOTFILES_DIR"
echo "==> Целевой HOME: $HOME_DIR"
echo ""

# Проверка зависимостей
check_dep() {
    if ! command -v "$1" &>/dev/null; then
        echo "  [!] Не найден: $1"
    fi
}

echo "--- Проверка зависимостей ---"
check_dep niri
check_dep waybar
check_dep fuzzel
check_dep mako
check_dep foot
check_dep kitty
check_dep fish
check_dep starship
check_dep eww
check_dep hyprland
check_dep btop
check_dep nvim
check_dep swww
check_dep playerctl
check_dep pactl
check_dep wlogout
check_dep rsync
echo ""

# Функция создания симлинка
link_config() {
    local src="$DOTFILES_DIR/$1"
    local dst="$HOME_DIR/$2"

    if [ ! -e "$src" ]; then
        echo "  - пропущен (нет в dotfiles): $1"
        return
    fi

    # Если уже симлинк на этот файл — пропустить
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  = уже привязан: $2"
        return
    fi

    # Бэкап существующего файла/папки
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        local backup="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
        echo "  ~ бэкап: $2 → $(basename "$backup")"
        mv "$dst" "$backup"
    elif [ -L "$dst" ]; then
        rm "$dst"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "  ✓ $2"
}

echo "--- Файлы в HOME ---"
link_config "home/.zshrc"      ".zshrc"
link_config "home/.p10k.zsh"   ".p10k.zsh"
link_config "home/.bash_profile" ".bash_profile"
link_config "home/.bashrc"     ".bashrc"
link_config "home/.gtkrc-2.0"  ".gtkrc-2.0"
link_config "home/.gitconfig"  ".gitconfig"
link_config "home/.fonts.conf" ".fonts.conf"

echo ""
echo "--- .config ---"
link_config ".config/niri"       ".config/niri"
link_config ".config/waybar"     ".config/waybar"
link_config ".config/fuzzel"     ".config/fuzzel"
link_config ".config/mako"       ".config/mako"
link_config ".config/foot"       ".config/foot"
link_config ".config/kitty"      ".config/kitty"
link_config ".config/fish"       ".config/fish"
link_config ".config/starship.toml" ".config/starship.toml"
link_config ".config/gtk-3.0"    ".config/gtk-3.0"
link_config ".config/gtk-4.0"    ".config/gtk-4.0"
link_config ".config/wlogout"    ".config/wlogout"
link_config ".config/eww"        ".config/eww"
link_config ".config/ags"        ".config/ags"
link_config ".config/quickshell" ".config/quickshell"
link_config ".config/hypr"       ".config/hypr"
link_config ".config/matugen"    ".config/matugen"
link_config ".config/btop"       ".config/btop"
link_config ".config/nvim"       ".config/nvim"
link_config ".config/mpv"        ".config/mpv"
link_config ".config/git"        ".config/git"
link_config ".config/zshrc.d"    ".config/zshrc.d"
link_config ".config/cava"       ".config/cava"
link_config ".config/easyeffects" ".config/easyeffects"

echo ""
echo "==> Готово!"
echo ""
echo "Следующие шаги:"
echo "  1. Установи oh-my-zsh: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
echo "  2. Установи плагины zsh: см. PACKAGES.md"
echo "  3. Для AGS: cd ~/.config/ags && npm install"
echo "  4. Для nvim: запусти nvim — lazy.nvim установит плагины автоматически"
echo "  5. Настрой мониторы в ~/.config/niri/config.kdl (секция output)"
echo "  6. Настрой мониторы в ~/.config/hypr/monitors.conf"
