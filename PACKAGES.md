# Пакеты для установки на новой машине

## Основное окружение (Wayland / Niri)

```bash
sudo dnf install \
  niri \
  fuzzel \
  foot \
  kitty \
  fish \
  starship \
  playerctl \
  pamixer \
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
  cava \
  easyeffects \
  polkit-gnome \
  xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk \
  wireguard-tools \
  blueman \
  network-manager-applet
```

## Noctalia (bar, notifs, lock, wallpaper, theming)

Установка через официальный скрипт: https://noctalia.dev/

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

chsh -s $(which zsh)
```

## Шрифты

```bash
sudo dnf install \
  jetbrains-mono-fonts \
  noto-fonts \
  noto-fonts-cjk \
  fontawesome-fonts \
  material-symbols-fonts

# Nerd Fonts — скачать с https://www.nerdfonts.com/font-downloads
# и положить в ~/.local/share/fonts/
fc-cache -fv
```

## Курсор

```bash
sudo dnf install bibata-cursor-themes
```

## GTK темы

```bash
sudo dnf install breeze-icon-theme breeze-gtk
```

## Настройка после установки

1. Настрой мониторы в `~/.config/niri/config.kdl` — секция `output`
2. В Noctalia `settings.json` поправь `osd.monitors`, `notifications.monitors`, `wallpaper.monitorDirectories`
3. SSH ключи добавить вручную в `~/.ssh/`
