#!/usr/bin/env bash
# install.sh — устанавливает пакеты и dotfiles на новой машине
# Запускать на целевой машине (ноут)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

echo "==> Установка dotfiles из $DOTFILES_DIR"
echo "==> Целевой HOME: $HOME_DIR"
echo ""

# ─── 1. ПАКЕТЫ ────────────────────────────────────────────────────────────────

install_packages() {
    echo "--- Установка пакетов (DNF) ---"

    sudo dnf install -y \
        niri \
        waybar \
        fuzzel \
        mako \
        foot \
        kitty \
        fish \
        starship \
        wlogout \
        hyprland \
        hypridle \
        hyprlock \
        btop \
        neovim \
        swww \
        playerctl \
        pamixer \
        wireplumber \
        pipewire \
        wl-clipboard \
        grim \
        slurp \
        rsync \
        git \
        curl \
        wget \
        eza \
        fzf \
        mpv \
        cava \
        zsh \
        polkit-gnome \
        xdg-desktop-portal-gnome \
        xdg-desktop-portal-gtk \
        tesseract \
        tesseract-langpack-rus \
        wireguard-tools \
        blueman \
        network-manager-applet \
        easyeffects \
        jetbrains-mono-fonts \
        noto-fonts \
        fontawesome-fonts \
        breeze-icon-theme \
        breeze-gtk \
        nodejs \
        npm

    echo ""

    # Rust (нужен для eww и matugen)
    if ! command -v cargo &>/dev/null; then
        echo "--- Установка Rust ---"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        echo "  = Rust уже установлен"
    fi

    # eww
    if ! command -v eww &>/dev/null; then
        echo "--- Сборка eww ---"
        local tmp_dir
        tmp_dir=$(mktemp -d)
        git clone --depth=1 https://github.com/elkowar/eww "$tmp_dir/eww"
        cd "$tmp_dir/eww"
        cargo build --release --no-default-features --features wayland
        sudo install -m755 target/release/eww /usr/local/bin/eww
        cd "$DOTFILES_DIR"
        rm -rf "$tmp_dir"
    else
        echo "  = eww уже установлен"
    fi

    # matugen
    if ! command -v matugen &>/dev/null; then
        echo "--- Установка matugen ---"
        cargo install matugen
    else
        echo "  = matugen уже установлен"
    fi

    echo ""
}

# ─── 2. ZSH / OH-MY-ZSH ───────────────────────────────────────────────────────

install_zsh() {
    echo "--- Настройка Zsh ---"

    # oh-my-zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "  Установка oh-my-zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "  = oh-my-zsh уже установлен"
    fi

    # Powerlevel10k
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        echo "  Установка Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    else
        echo "  = Powerlevel10k уже установлен"
    fi

    # zsh-autosuggestions
    local autosug_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [ ! -d "$autosug_dir" ]; then
        echo "  Установка zsh-autosuggestions..."
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$autosug_dir"
    else
        echo "  = zsh-autosuggestions уже установлен"
    fi

    # zsh-syntax-highlighting
    local synhl_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    if [ ! -d "$synhl_dir" ]; then
        echo "  Установка zsh-syntax-highlighting..."
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$synhl_dir"
    else
        echo "  = zsh-syntax-highlighting уже установлен"
    fi

    # Сменить оболочку на zsh
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "  Смена оболочки на zsh..."
        chsh -s "$(which zsh)"
    else
        echo "  = zsh уже оболочка по умолчанию"
    fi

    echo ""
}

# ─── 3. СИМЛИНКИ ──────────────────────────────────────────────────────────────

link_config() {
    local src="$DOTFILES_DIR/$1"
    local dst="$HOME_DIR/$2"

    if [ ! -e "$src" ]; then
        echo "  - пропущен (нет в dotfiles): $1"
        return
    fi

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  = уже привязан: $2"
        return
    fi

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

install_dotfiles() {
    echo "--- Файлы в HOME ---"
    link_config "home/.zshrc"        ".zshrc"
    link_config "home/.p10k.zsh"     ".p10k.zsh"
    link_config "home/.bash_profile" ".bash_profile"
    link_config "home/.bashrc"       ".bashrc"
    link_config "home/.gtkrc-2.0"    ".gtkrc-2.0"
    link_config "home/.gitconfig"    ".gitconfig"
    link_config "home/.fonts.conf"   ".fonts.conf"

    echo ""
    echo "--- .config ---"
    link_config ".config/niri"        ".config/niri"
    link_config ".config/waybar"      ".config/waybar"
    link_config ".config/fuzzel"      ".config/fuzzel"
    link_config ".config/mako"        ".config/mako"
    link_config ".config/foot"        ".config/foot"
    link_config ".config/kitty"       ".config/kitty"
    link_config ".config/fish"        ".config/fish"
    link_config ".config/starship.toml" ".config/starship.toml"
    link_config ".config/gtk-3.0"     ".config/gtk-3.0"
    link_config ".config/gtk-4.0"     ".config/gtk-4.0"
    link_config ".config/wlogout"     ".config/wlogout"
    link_config ".config/eww"         ".config/eww"
    link_config ".config/ags"         ".config/ags"
    link_config ".config/quickshell"  ".config/quickshell"
    link_config ".config/hypr"        ".config/hypr"
    link_config ".config/matugen"     ".config/matugen"
    link_config ".config/btop"        ".config/btop"
    link_config ".config/nvim"        ".config/nvim"
    link_config ".config/mpv"         ".config/mpv"
    link_config ".config/git"         ".config/git"
    link_config ".config/zshrc.d"     ".config/zshrc.d"
    link_config ".config/cava"        ".config/cava"
    link_config ".config/easyeffects" ".config/easyeffects"

    echo ""
}

# ─── 4. AGS ───────────────────────────────────────────────────────────────────

install_ags() {
    echo "--- AGS: npm install ---"
    if [ -d "$HOME_DIR/.config/ags" ]; then
        cd "$HOME_DIR/.config/ags"
        npm install
        cd "$DOTFILES_DIR"
        echo "  ✓ AGS зависимости установлены"
    fi
    echo ""
}

# ─── MAIN ─────────────────────────────────────────────────────────────────────

install_packages
install_zsh
install_dotfiles
install_ags

echo "==> Всё готово!"
echo ""
echo "Следующие шаги:"
echo "  1. Настрой мониторы: ~/.config/niri/config.kdl (секция output)"
echo "  2. Настрой мониторы: ~/.config/hypr/monitors.conf"
echo "  3. Добавь SSH ключи в ~/.ssh/"
echo "  4. Запусти nvim — lazy.nvim установит плагины автоматически"
echo "  5. Перезайди в терминал чтобы применился zsh"
