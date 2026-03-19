#!/bin/bash
# Connect or toggle a specific VPN profile
# Usage: vpn-connect.sh <name>
target="$1"
[ -z "$target" ] && exit 1

active=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
    | grep ':wireguard' | cut -d: -f1)

if [ "$active" = "$target" ]; then
    nmcli connection down "$active"
else
    [ -n "$active" ] && nmcli connection down "$active"
    nmcli connection up "$target"
fi
