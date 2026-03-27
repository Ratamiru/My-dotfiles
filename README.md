# Dotfiles — Ratamiru

Конфиги рабочего стола на базе **Niri** (Wayland compositor).

## Стек

| Компонент | Программа |
|-----------|-----------|
| WM | Niri |
| Bar / Notifs / Lock / Wallpaper / Theming | Noctalia |
| Launcher | Fuzzel |
| Terminal | Foot / Kitty |
| Shell | Zsh (oh-my-zsh + p10k) / Fish |
| Prompt | Starship (в fish) |
| Editor | Neovim (LazyVim) |
| Monitor | Btop |
| Audio FX | EasyEffects |
| Visualizer | Cava |

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

### 4. Настройка под ноут

- **Мониторы**: отредактируй `~/.config/niri/config.kdl` — закомментируй блок `output "HDMI-A-1"`, оставь только `output "eDP-1"`
- **Noctalia мониторы**: в `settings.json` поправь `osd.monitors`, `notifications.monitors` и `wallpaper.monitorDirectories`
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
