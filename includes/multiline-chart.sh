#!/usr/bin/env bash
# multiline-chart.sh - Terminal multi-series line chart using Unicode box-drawing characters
#
# Renders multiple data series on a single chart with colored lines and a legend.
# Each series is specified via a -s flag pointing to a JSON file of [{time, value}, ...].
#
# Usage:
#   multiline-chart.sh [options] -s "Name,color,file" [-s "Name2,color2,file2" ...]
#
# Parameters:
#   -height      Chart height in rows (default: terminal height / 2 - 3)
#   -width       Chart width in columns (default: terminal width - 5)
#   -timefmt     Time format: "HH:MM:SS" (default), "MM:SS", or "HH:MM"
#   -label-color Color of y-axis value labels (default: none)
#   -time-color  Color of x-axis timestamp labels (default: none)
#   -axis-color  Color of axis lines and legend border (default: none)
#   -min         Force minimum y-axis value (default: auto from data)
#   -max         Force maximum y-axis value (default: auto from data)
#   -no-legend   Suppress the inline legend box (default: legend shown)
#   -s           Series: "Name,color,filepath" (repeatable)
#
# Supported colors:
#   black, red, green, yellow, blue, magenta, cyan, white,
#   light-gray, dark-gray, light-red, light-green, light-yellow,
#   light-blue, light-magenta, light-cyan
#   Or raw ANSI codes, e.g. "38;2;255;82;82" for RGB

# Defaults
_term_cols=$(( $(tput cols 2>/dev/null || echo 80) - 5 ))
_term_lines=$(( $(tput lines 2>/dev/null || echo 40) / 2 - 3 ))

height="${_term_lines}"
width="${_term_cols}"
timefmt="HH:MM:SS"
label_color=""
time_color=""
axis_color=""
y_min=""
y_max=""
show_legend=1

# Series arrays
declare -a series_names=()
declare -a series_colors=()
declare -a series_files=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -height)      height="$2";      shift 2 ;;
        -width)       width="$2";       shift 2 ;;
        -timefmt)     timefmt="$2";     shift 2 ;;
        -label-color) label_color="$2"; shift 2 ;;
        -time-color)  time_color="$2";  shift 2 ;;
        -axis-color)  axis_color="$2";  shift 2 ;;
        -min)         y_min="$2";       shift 2 ;;
        -max)         y_max="$2";       shift 2 ;;
        -no-legend)   show_legend=0;    shift ;;
        -s)
            IFS=',' read -r name color filepath <<< "$2"
            series_names+=("$name")
            series_colors+=("$color")
            series_files+=("$filepath")
            shift 2
            ;;
        *)            shift ;;
    esac
done

num_series=${#series_names[@]}
if [[ $num_series -eq 0 ]]; then
    echo "Error: No series specified. Use -s \"Name,color,file\" to add series." >&2
    exit 1
fi

# Map color name to ANSI code
_color_code() {
    case "$1" in
        black)         echo "30" ;;
        red)           echo "31" ;;
        green)         echo "32" ;;
        yellow)        echo "33" ;;
        blue)          echo "34" ;;
        magenta)       echo "35" ;;
        cyan)          echo "36" ;;
        white)         echo "37" ;;
        dark-gray)     echo "90" ;;
        light-gray)    echo "37" ;;
        light-red)     echo "91" ;;
        light-green)   echo "92" ;;
        light-yellow)  echo "93" ;;
        light-blue)    echo "94" ;;
        light-magenta) echo "95" ;;
        light-cyan)    echo "96" ;;
        "")            echo "" ;;
        *)             echo "$1" ;;
    esac
}

label_ansi=$(_color_code "$label_color")
time_ansi=$(_color_code "$time_color")
axis_ansi=$(_color_code "$axis_color")

# Build color list for awk (pipe-separated ANSI codes)
color_list=""
name_list=""
for i in $(seq 0 $(( num_series - 1 ))); do
    code=$(_color_code "${series_colors[$i]}")
    [[ -n "$color_list" ]] && color_list+="|"
    color_list+="$code"
    [[ -n "$name_list" ]] && name_list+="|"
    name_list+="${series_names[$i]}"
done

# Map timefmt to jq strftime format
case "$timefmt" in
    MM:SS)    jq_fmt="%M:%S" ;;
    HH:MM)   jq_fmt="%H:%M" ;;
    *)        jq_fmt="%H:%M:%S" ;;
esac

# Extract data from each series file, prefixed with series index
combined_data=""
for i in $(seq 0 $(( num_series - 1 ))); do
    file="${series_files[$i]}"
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        exit 1
    fi
    series_data=$(cat "$file" | jq -r --arg fmt "$jq_fmt" --arg idx "$i" \
        '.[] | "\($idx) \(.time | localtime | strftime($fmt)) \(.value)"')
    combined_data+="$series_data"$'\n'
done

this_dir=$(dirname "${BASH_SOURCE[0]}")

# Feed combined data into gawk
echo "$combined_data" | \
gawk -v plot_height="$height" -v total_width="$width" \
    -v c_label="$label_ansi" -v c_time="$time_ansi" -v c_axis="$axis_ansi" \
    -v forced_min="$y_min" -v forced_max="$y_max" \
    -v num_series="$num_series" \
    -v color_list="$color_list" -v name_list="$name_list" \
    -v show_legend="$show_legend" \
    -f "${this_dir}/awk/multiline-asciichart.awk"
