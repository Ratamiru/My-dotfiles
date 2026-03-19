#!/usr/bin/env bash
# Cycle through audio output sinks (speakers <-> headphones etc.)
# Usage: audio-switch.sh [cycle|status]

cycle_sink() {
    # Get all available sinks (not monitors, not virtual)
    mapfile -t sinks < <(pactl list short sinks | awk '{print $2}')

    if [[ ${#sinks[@]} -lt 2 ]]; then
        notify-send -t 2000 "Audio" "Only one output device available"
        return
    fi

    # Get current default sink
    current=$(pactl get-default-sink)

    # Find current index and cycle to next
    for i in "${!sinks[@]}"; do
        if [[ "${sinks[$i]}" == "$current" ]]; then
            next_idx=$(( (i + 1) % ${#sinks[@]} ))
            pactl set-default-sink "${sinks[$next_idx]}"

            # Move all playing streams to the new sink
            pactl list short sink-inputs | awk '{print $1}' | while read -r input; do
                pactl move-sink-input "$input" "${sinks[$next_idx]}"
            done

            # Get friendly description for notification
            desc=$(pactl list sinks | awk -v name="${sinks[$next_idx]}" '
                $0 ~ "Name: " name {found=1}
                found && /Description:/ {sub(/.*Description: /, ""); print; exit}
            ')
            notify-send -t 2000 "Audio Output" "$desc"
            return
        fi
    done
}

get_status() {
    current=$(pactl get-default-sink)
    desc=$(pactl list sinks | awk -v name="$current" '
        $0 ~ "Name: " name {found=1}
        found && /Description:/ {sub(/.*Description: /, ""); print; exit}
    ')
    echo "$desc"
}

case "${1:-cycle}" in
    cycle)  cycle_sink ;;
    status) get_status ;;
esac
