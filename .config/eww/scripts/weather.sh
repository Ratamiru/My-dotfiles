#!/usr/bin/env bash
# Fetches weather for Tomsk via wttr.in, caches for 10 min

CACHE="/tmp/eww-weather-cache.json"
CACHE_MAX=600 # seconds

# Weather code → Nerd Font icon mapping
weather_icon() {
  case "$1" in
    113) echo "" ;;         # Clear/Sunny
    116) echo "" ;;         # Partly cloudy
    119|122) echo "" ;;     # Cloudy / Overcast
    143|248|260) echo "" ;; # Fog / Mist
    176|263|266) echo "" ;; # Light rain
    179|227|323|326) echo "" ;; # Light snow
    182|185|281|284|311|314|317) echo "" ;; # Sleet
    200|386|389|392|395) echo "" ;; # Thunder
    293|296|299|302|305|308|353|356|359|362|365) echo "" ;; # Rain
    230|329|332|335|338|368|371|374|377) echo "" ;; # Snow
    *) echo "" ;;
  esac
}

# Use cache if fresh enough
if [[ -f "$CACHE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
  if (( age < CACHE_MAX )); then
    cat "$CACHE"
    exit 0
  fi
fi

# Fetch data
raw=$(curl -sf "https://wttr.in/Tomsk?format=j1" 2>/dev/null)

if [[ -z "$raw" ]]; then
  # Fallback: return cache if exists, else default
  if [[ -f "$CACHE" ]]; then
    cat "$CACHE"
  else
    echo '{"temp":"--","desc":"Offline","humidity":"--","wind":"--","icon":"","forecast":[]}'
  fi
  exit 0
fi

# Parse current conditions
temp=$(echo "$raw" | jq -r '.current_condition[0].temp_C')
desc=$(echo "$raw" | jq -r '.current_condition[0].weatherDesc[0].value')
humidity=$(echo "$raw" | jq -r '.current_condition[0].humidity')
wind=$(echo "$raw" | jq -r '.current_condition[0].windspeedKmph')
code=$(echo "$raw" | jq -r '.current_condition[0].weatherCode')
icon=$(weather_icon "$code")

# Parse 3-day forecast
forecast="["
for i in 0 1 2; do
  fdate=$(echo "$raw" | jq -r ".weather[$i].date")
  ftemp=$(echo "$raw" | jq -r ".weather[$i].avgtempC")
  fcode=$(echo "$raw" | jq -r ".weather[$i].hourly[4].weatherCode")
  ficon=$(weather_icon "$fcode")
  # Short date: day/month
  short_date=$(date -d "$fdate" "+%d/%m" 2>/dev/null || echo "$fdate")
  [[ $i -gt 0 ]] && forecast+=","
  forecast+="{\"date\":\"$short_date\",\"temp\":\"${ftemp}°\",\"icon\":\"$ficon\"}"
done
forecast+="]"

result="{\"temp\":\"$temp\",\"desc\":\"$desc\",\"humidity\":\"$humidity\",\"wind\":\"$wind\",\"icon\":\"$icon\",\"forecast\":$forecast}"

echo "$result" > "$CACHE"
echo "$result"
