#!/usr/bin/env bash
# Bluetooth status for waybar (return-type: json)
# Usage: bluetooth.sh [status|toggle]

status() {
    powered=$(bluetoothctl show 2>/dev/null | grep -c "Powered: yes")

    if [[ "$powered" -eq 0 ]]; then
        echo '{"text":"off","tooltip":"Bluetooth off","class":"off"}'
        return
    fi

    # Get connected devices
    mapfile -t connected < <(bluetoothctl devices Connected 2>/dev/null | sed 's/^Device [^ ]* //')

    if [[ ${#connected[@]} -gt 0 && -n "${connected[0]}" ]]; then
        names=$(printf '%s, ' "${connected[@]}")
        names="${names%, }"
        # Escape for JSON
        names="${names//\"/\\\"}"
        echo "{\"text\":\"${connected[0]}\",\"tooltip\":\"${names}\",\"class\":\"connected\"}"
    else
        echo '{"text":"on","tooltip":"No devices connected","class":"on"}'
    fi
}

toggle() {
    powered=$(bluetoothctl show 2>/dev/null | grep -c "Powered: yes")
    if [[ "$powered" -eq 1 ]]; then
        bluetoothctl power off >/dev/null 2>&1
        notify-send -t 2000 "Bluetooth" "Disabled"
    else
        bluetoothctl power on >/dev/null 2>&1
        notify-send -t 2000 "Bluetooth" "Enabled"
    fi
}

case "${1:-status}" in
    status) status ;;
    toggle) toggle ;;
esac
