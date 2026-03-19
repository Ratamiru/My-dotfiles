# Пакеты для установки на новой машине

## Основное окружение (Wayland / Niri)

```bash
# Fedora / RPM-based
sudo dnf install \
  niri \
  waybar \
  fuzzel \
  mako \
  foot \
  kitty \
  fish \
  starship \
  swww \
  wlogout \
  playerctl \
  pamixer \
  pactl \
  wl-clipboard \
  grim \
  slurp \
  btop \
  neovim \
  rsync \
  git \
  curl \
  wget \
  eza \
  fzf \
  mpv \
  cava
```

## Zsh и плагины

```bash
sudo dnf install zsh

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Плагины
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Powerlevel10k тема
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Сделать zsh оболочкой по умолчанию
chsh -s $(which zsh)
```

## AGS (Bar для Niri)

```bash
# Требует ags и astal (сборка из исходников или AUR/COPR)
# https://github.com/Aylur/ags

cd ~/.config/ags
npm install
```

## EWW (Dashboard)

```bash
# Собрать из исходников: https://github.com/elkowar/eww
cargo install eww --locked

# Или через пакетный менеджер если доступен
sudo dnf install eww
```

## Hyprland (альтернативный WM)

```bash
sudo dnf install hyprland hypridle hyprlock hyprshot
```

## Шрифты

```bash
sudo dnf install \
  jetbrains-mono-fonts \
  noto-fonts \
  noto-fonts-cjk \
  fontawesome-fonts \
  material-symbols-fonts

# Nerd Fonts (JetBrains Mono Nerd Font)
# Скачать с https://www.nerdfonts.com/font-downloads
# и положить в ~/.local/share/fonts/
fc-cache -fv
```

## Курсор

```bash
# Bibata-Original-Classic
# Установить через пакетный менеджер или вручную
sudo dnf install bibata-cursor-themes
# или скачать с https://github.com/ful1e5/Bibata_Cursor
```

## GTK темы

```bash
sudo dnf install breeze-icon-theme breeze-gtk
```

## Дополнительные утилиты

```bash
sudo dnf install \
  polkit-gnome \
  xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk \
  tesseract \
  tesseract-langpack-rus \
  wireguard-tools \
  blueman \
  network-manager-applet

# EasyEffects (аудио)
sudo dnf install easyeffects

# matugen (генератор цветовых схем)
cargo install matugen
```

## Rust / Cargo

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Настройка после установки

1. Настрой мониторы в `~/.config/niri/config.kdl` — секция `output`
2. Настрой мониторы в `~/.config/hypr/monitors.conf`
3. Для ноута убери конфиг HDMI-A-1 из niri config (или закомментируй)
4. Настрой `~/.config/fish/auto-Hypr.fish` если нужен автозапуск
5. SSH ключи добавить вручную в `~/.ssh/`
