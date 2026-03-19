# Dotfiles — Ratamiru

Конфиги рабочего стола на базе **Niri** (Wayland compositor).

## Стек

| Компонент | Программа |
|-----------|-----------|
| WM | Niri (основной) / Hyprland (запасной) |
| Bar | AGS (ags) + Waybar |
| Dashboard | EWW |
| Launcher | Fuzzel |
| Notifications | Mako |
| Terminal | Foot / Kitty |
| Shell | Zsh (oh-my-zsh + p10k) / Fish |
| Prompt | Starship (в fish) |
| Lock screen | Hyprlock |
| Power menu | Wlogout |
| Wallpaper | swww |
| Colors | Matugen |
| Editor | Neovim (LazyVim) |
| Monitor | Btop |

## Быстрый старт

### 1. Клонировать репозиторий

```bash
git clone <repo-url> ~/dotfiles
```

### 2. Установить пакеты

```bash
# Смотри PACKAGES.md
```

### 3. Установить dotfiles

```bash
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

### 4. AGS (после install.sh)

```bash
cd ~/.config/ags
npm install
```

### 5. Настройка под ноут

- **Мониторы**: отредактируй `~/.config/niri/config.kdl` — закомментируй/удали блок `output "HDMI-A-1"`, оставь только `output "eDP-1"`
- **Hyprland мониторы**: отредактируй `~/.config/hypr/monitors.conf`
- **SSH ключи**: добавь вручную в `~/.ssh/`

## Обновление dotfiles с текущей машины

```bash
cd ~/dotfiles
./collect.sh
git add -A
git commit -m "update configs"
git push
```

## Структура

```
dotfiles/
├── home/           # файлы прямо в $HOME (.zshrc, .gitconfig, и т.д.)
├── .config/        # содержимое ~/.config/
├── collect.sh      # сбор конфигов с текущей машины
├── install.sh      # установка на новой машине
├── PACKAGES.md     # список пакетов для установки
└── README.md
```
