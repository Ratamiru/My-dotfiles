#!/usr/bin/env bash
# Output JSON list of audio sinks for eww, updates on changes.
# Each sink: {"name": "...", "desc": "...", "active": true/false}

emit() {
    default=$(pactl get-default-sink)
    json="["
    first=true
    while IFS=$'\t' read -r _ name _ _ _; do
        desc=$(pactl list sinks | awk -v n="$name" '
            $0 ~ "Name: " n {found=1}
            found && /Description:/ {sub(/.*Description: /, ""); print; exit}
        ')
        active=false
        [[ "$name" == "$default" ]] && active=true
        $first || json+=","
        first=false
        # Escape double quotes in desc
        desc="${desc//\"/\\\"}"
        json+="{\"name\":\"$name\",\"desc\":\"$desc\",\"active\":$active}"
    done < <(pactl list short sinks)
    json+="]"
    echo "$json"
}

# Initial emit
emit

# Re-emit on any sink change
pactl subscribe 2>/dev/null | grep --line-buffered -E '(sink|server)' | while read -r _; do
    sleep 0.1
    emit
done
