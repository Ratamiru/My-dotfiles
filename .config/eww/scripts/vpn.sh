#!/bin/bash
# EWW VPN status poller — outputs JSON

VPNS=("wg0" "OutlineVPN")

active=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
    | grep ':wireguard' | cut -d: -f1)

vpn_list="["
first=true
for vpn in "${VPNS[@]}"; do
    [ "$first" = false ] && vpn_list+=","
    first=false
    if [ "$vpn" = "$active" ]; then
        vpn_list+="{\"name\":\"$vpn\",\"active\":true}"
    else
        vpn_list+="{\"name\":\"$vpn\",\"active\":false}"
    fi
done
vpn_list+="]"

if [ -n "$active" ]; then
    printf '{"connected":true,"active":"%s","vpns":%s}\n' "$active" "$vpn_list"
else
    printf '{"connected":false,"active":"","vpns":%s}\n' "$vpn_list"
fi
