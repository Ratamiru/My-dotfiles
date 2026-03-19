#!/usr/bin/env python3
import json
import os
import psutil
import argparse
from pathlib import Path

CACHE_DIR = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache'))
HISTORY_FILE = CACHE_DIR / 'mem_usage_history.json'
DEFAULT_HISTORY_DEPTH = 40

BRAILLE_PATTERNS = {
    (0, 0): '⠀', (1, 0): '⡀', (2, 0): '⡄', (3, 0): '⡆', (4, 0): '⡇',
    (0, 1): '⢀', (1, 1): '⣀', (2, 1): '⣄', (3, 1): '⣆', (4, 1): '⣇',
    (0, 2): '⢠', (1, 2): '⣠', (2, 2): '⣤', (3, 2): '⣦', (4, 2): '⣧',
    (0, 3): '⢰', (1, 3): '⣰', (2, 3): '⣴', (3, 3): '⣶', (4, 3): '⣷',
    (0, 4): '⢸', (1, 4): '⣸', (2, 4): '⣼', (3, 4): '⣾', (4, 4): '⣿',
}

def get_braille_char(left_val, right_val):
    left_level = max(1, min(int(left_val * 4 / 100), 4))
    right_level = max(1, min(int(right_val * 4 / 100), 4))
    return BRAILLE_PATTERNS.get((left_level, right_level), '⣀')

def load_data():
    try:
        with open(HISTORY_FILE, 'r') as f:
            data = json.load(f)
            if isinstance(data, list):
                return {"history": data, "show_graph": True}
            return data
    except (FileNotFoundError, json.JSONDecodeError):
        return {"history": [], "show_graph": True}

def save_data(data):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(HISTORY_FILE, 'w') as f:
        json.dump(data, f)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', nargs='?', help='Command: toggle')
    parser.add_argument('-d', '--depth', type=int, default=DEFAULT_HISTORY_DEPTH)
    args = parser.parse_args()

    history_depth = args.depth + (args.depth % 2)
    data = load_data()

    if args.command == "toggle":
        data["show_graph"] = not data.get("show_graph", True)
        save_data(data)
        return

    mem = psutil.virtual_memory()
    current_usage = mem.percent

    history = data["history"]
    history.append(current_usage)
    if len(history) > history_depth:
        history = history[-history_depth:]

    if data.get("show_graph", True):
        padded = [0.0] * (history_depth - len(history)) + history
        graph = ''.join(
            get_braille_char(padded[i], padded[i + 1] if i + 1 < history_depth else 0.0)
            for i in range(0, history_depth, 2)
        )
        text = graph
    else:
        text = f"{current_usage:.1f}%"

    data["history"] = history
    save_data(data)

    used_gb = mem.used / 1024 ** 3
    total_gb = mem.total / 1024 ** 3

    print(json.dumps({
        "text": text,
        "tooltip": f"{used_gb:.1f} / {total_gb:.1f} GiB ({current_usage:.1f}%)",
        "class": "mem-history"
    }))

if __name__ == "__main__":
    main()
