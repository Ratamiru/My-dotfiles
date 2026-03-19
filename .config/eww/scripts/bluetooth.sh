#!/usr/bin/env bash
# Bluetooth device list for eww. Outputs JSON, re-emits on changes.
# Each device: {"mac":"...","name":"...","connected":bool,"icon":"..."}

get_icon() {
    local name="${1,,}"
    case "$name" in
        *headphone*|*airpod*|*buds*|*earphone*) echo "󰋋" ;;
        *speaker*|*soundbar*)                    echo "󰓃" ;;
        *mouse*|*trackpad*)                      echo "󰍽" ;;
        *keyboard*|*keychron*)                    echo "󰌌" ;;
        *phone*|*iphone*|*galaxy*|*pixel*)       echo "󰏲" ;;
        *controller*|*gamepad*|*xbox*|*dual*)    echo "󰊗" ;;
        *)                                        echo "󰂯" ;;
    esac
}

emit() {
    powered=$(bluetoothctl show 2>/dev/null | grep -c "Powered: yes")

    if [[ "$powered" -eq 0 ]]; then
        echo '{"powered":false,"devices":[]}'
        return
    fi

    # Get paired devices
    json='{"powered":true,"devices":['
    first=true

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | sed 's/^Device [^ ]* //')
        name="${name//\"/\\\"}"

        # Check if connected
        connected=false
        if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
            connected=true
        fi

        icon=$(get_icon "$name")

        $first || json+=","
        first=false
        json+="{\"mac\":\"$mac\",\"name\":\"$name\",\"connected\":$connected,\"icon\":\"$icon\"}"
    done < <(bluetoothctl devices Paired 2>/dev/null)

    json+=']}'
    echo "$json"
}

# Initial
emit

# Watch for changes via bluetoothctl monitor
bluetoothctl --monitor 2>/dev/null | while read -r line; do
    case "$line" in
        *"CHG"*"Connected"*|*"DEL"*|*"NEW"*|*"Powered"*)
            sleep 0.3
            emit
            ;;
    esac
done
