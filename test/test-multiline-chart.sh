#!/usr/bin/env bash
# Generate 3 sine waves at different offsets/frequencies and render with multiline-chart.sh

CLI_DIR=$(git rev-parse --show-toplevel)
now=$(date +%s)
tmpdir=$(mktemp -d)

# Series 1: Extruder temp ~200-220
json="["
for i in $(seq 0 79); do
    t=$(echo "$now + $i * 30" | bc)
    v=$(awk "BEGIN { printf \"%.2f\", 210 + 10 * sin($i / 5.0) }")
    [[ $i -gt 0 ]] && json+=","
    json+=$'\n'"  {\"index\":$i,\"time\":$t,\"value\":$v}"
done
json+=$'\n'"]"
echo "$json" > "$tmpdir/extruder.json"

# Series 2: Bed temp ~55-65
json="["
for i in $(seq 0 79); do
    t=$(echo "$now + $i * 30" | bc)
    v=$(awk "BEGIN { printf \"%.2f\", 60 + 5 * sin($i / 7.0 + 1.0) }")
    [[ $i -gt 0 ]] && json+=","
    json+=$'\n'"  {\"index\":$i,\"time\":$t,\"value\":$v}"
done
json+=$'\n'"]"
echo "$json" > "$tmpdir/bed.json"

# Series 3: Chamber temp ~35-45
json="["
for i in $(seq 0 79); do
    t=$(echo "$now + $i * 30" | bc)
    v=$(awk "BEGIN { printf \"%.2f\", 40 + 5 * sin($i / 10.0 + 2.0) }")
    [[ $i -gt 0 ]] && json+=","
    json+=$'\n'"  {\"index\":$i,\"time\":$t,\"value\":$v}"
done
json+=$'\n'"]"
echo "$json" > "$tmpdir/chamber.json"

bash "${CLI_DIR}/includes/multiline-chart.sh" \
    -height 25 -width 120 -timefmt MM:SS \
    -label-color cyan \
    -time-color magenta \
    -axis-color light-gray \
    -min 0 \
    -s "Extruder,red,$tmpdir/extruder.json" \
    -s "Bed Temp,yellow,$tmpdir/bed.json" \
    -s "Chamber,green,$tmpdir/chamber.json"

rm -rf "$tmpdir"
