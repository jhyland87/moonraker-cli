#!/usr/bin/env bash
# Generate a sine wave and render it with chart.sh

CLI_DIR=$(git rev-parse --show-toplevel)

# Generate 80 points of sine wave data as JSON
now=$(date +%s)

json="["
for i in $(seq 0 79); do
    t=$(echo "$now + $i * 30" | bc)
    # sine wave: 200 + 10*sin(i/5)
    v=$(awk "BEGIN { printf \"%.2f\", 200 + 10 * sin($i / 5.0) }")
    [[ $i -gt 0 ]] && json+=","
    json+=$'\n'"  {\"index\":$i,\"time\":$t,\"value\":$v}"
done
json+=$'\n'"]"

echo "$json" | bash "${CLI_DIR}/includes/chart.sh" \
    -height 20 -width 120 -timefmt MM:SS \
    -line-color yellow \
    -label-color cyan \
    -time-color magenta \
    -axis-color light-gray
