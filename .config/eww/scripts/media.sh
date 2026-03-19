#!/usr/bin/env bash
# Streams MPRIS metadata via playerctl, downloads album art

ART_PATH="/tmp/eww-media-art"

download_art() {
  local url="$1"
  if [[ "$url" == http* ]]; then
    curl -sf -o "$ART_PATH" "$url" 2>/dev/null
    echo "$ART_PATH"
  elif [[ -f "$url" ]]; then
    echo "$url"
  else
    echo ""
  fi
}

output_json() {
  local title artist art_url art_local status
  status=$(playerctl status 2>/dev/null || echo "Stopped")
  title=$(playerctl metadata title 2>/dev/null || echo "")
  artist=$(playerctl metadata artist 2>/dev/null || echo "")
  art_url=$(playerctl metadata mpris:artUrl 2>/dev/null || echo "")

  # Convert file:// URIs
  art_url="${art_url/#file:\/\//}"

  art_local=$(download_art "$art_url")

  # Escape quotes in title/artist for JSON
  title="${title//\"/\\\"}"
  artist="${artist//\"/\\\"}"

  echo "{\"title\":\"$title\",\"artist\":\"$artist\",\"art\":\"$art_local\",\"status\":\"$status\"}"
}

# Initial output
output_json

# Listen for metadata/status changes
playerctl -F metadata -f '{{title}}\t{{artist}}\t{{mpris:artUrl}}\t{{status}}' 2>/dev/null | while IFS=$'\t' read -r title artist art_url status; do
  art_url="${art_url/#file:\/\//}"
  art_local=$(download_art "$art_url")
  title="${title//\"/\\\"}"
  artist="${artist//\"/\\\"}"
  echo "{\"title\":\"$title\",\"artist\":\"$artist\",\"art\":\"$art_local\",\"status\":\"$status\"}"
done
