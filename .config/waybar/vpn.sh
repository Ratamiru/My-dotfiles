#!/bin/bash
# Waybar VPN module helper
# Usage:
#   vpn.sh status   — JSON output for waybar
#   vpn.sh toggle   — connect/disconnect active VPN
#   vpn.sh switch   — switch between VPN profiles

VPNS=("wg0" "OutlineVPN")

get_active() {
    nmcli -t -f NAME,TYPE connection show --active | grep ':wireguard' | cut -d: -f1
}

case "${1:-status}" in
    status)
        active=$(get_active)
        if [ -n "$active" ]; then
            echo "{\"text\": \"$active\", \"class\": \"connected\", \"tooltip\": \"VPN: $active\"}"
        else
            echo "{\"text\": \"off\", \"class\": \"disconnected\", \"tooltip\": \"VPN disconnected\"}"
        fi
        ;;
    toggle)
        active=$(get_active)
        if [ -n "$active" ]; then
            nmcli connection down "$active"
        else
            # Connect the first available VPN
            for vpn in "${VPNS[@]}"; do
                if nmcli connection show "$vpn" &>/dev/null; then
                    nmcli connection up "$vpn" &
                    break
                fi
            done
        fi
        ;;
    switch)
        active=$(get_active)
        # Find next VPN in the list
        next="${VPNS[0]}"
        for i in "${!VPNS[@]}"; do
            if [ "${VPNS[$i]}" = "$active" ]; then
                next_idx=$(( (i + 1) % ${#VPNS[@]} ))
                next="${VPNS[$next_idx]}"
                break
            fi
        done
        [ -n "$active" ] && nmcli connection down "$active"
        nmcli connection up "$next" &
        ;;
esac
