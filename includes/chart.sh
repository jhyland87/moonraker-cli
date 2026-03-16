#!/usr/bin/env bash
# chart.sh - Terminal line chart using Unicode box-drawing characters
#
# Reads a JSON array of {time, value} objects from stdin and renders
# a clean line chart using: ┤ ┼ ╶ ─ ╰ ╭ ╮ ╯ │
#
# Usage:
#   echo "$json_data" | chart.sh [options]
#
# Parameters:
#   -height      Chart height in rows (default: terminal height / 2 - 3)
#   -width       Chart width in columns (default: terminal width - 5)
#   -timefmt     Time format: "HH:MM:SS" (default), "MM:SS", or "HH:MM"
#   -line-color  Color of the chart line (default: none)
#   -label-color Color of y-axis value labels (default: none)
#   -time-color  Color of x-axis timestamp labels (default: none)
#   -axis-color  Color of axis lines ┤┼─ (default: none)
#   -min         Force minimum y-axis value (default: auto from data)
#   -max         Force maximum y-axis value (default: auto from data)
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
line_color=""
label_color=""
time_color=""
axis_color=""
y_min=""
y_max=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -height)      height="$2";      shift 2 ;;
        -width)       width="$2";       shift 2 ;;
        -timefmt)     timefmt="$2";     shift 2 ;;
        -line-color)  line_color="$2";  shift 2 ;;
        -label-color) label_color="$2"; shift 2 ;;
        -time-color)  time_color="$2";  shift 2 ;;
        -axis-color)  axis_color="$2";  shift 2 ;;
        -min)         y_min="$2";       shift 2 ;;
        -max)         y_max="$2";       shift 2 ;;
        *)            shift ;;
    esac
done

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
        *)             echo "$1" ;;  # pass raw ANSI codes through
    esac
}

line_ansi=$(_color_code "$line_color")
label_ansi=$(_color_code "$label_color")
time_ansi=$(_color_code "$time_color")
axis_ansi=$(_color_code "$axis_color")

# Map timefmt to jq strftime format
case "$timefmt" in
    MM:SS)    jq_fmt="%M:%S" ;;
    HH:MM)   jq_fmt="%H:%M" ;;
    *)        jq_fmt="%H:%M:%S" ;;
esac

input=$(cat)

# Extract time (formatted) and value, one per line as "timestr value"
echo "$input" | jq -r --arg fmt "$jq_fmt" \
    '.[] | "\(.time | localtime | strftime($fmt)) \(.value)"' | \
awk -v plot_height="$height" -v total_width="$width" \
    -v c_line="$line_ansi" -v c_label="$label_ansi" \
    -v c_time="$time_ansi" -v c_axis="$axis_ansi" \
    -v forced_min="$y_min" -v forced_max="$y_max" '
BEGIN {
    n = 0
    reset = "\033[0m"
    if (c_line  != "") c_line  = "\033[" c_line  "m"
    if (c_label != "") c_label = "\033[" c_label "m"
    if (c_time  != "") c_time  = "\033[" c_time  "m"
    if (c_axis  != "") c_axis  = "\033[" c_axis  "m"
}
{
    times[n] = $1
    vals[n] = $2 + 0
    n++
}
END {
    if (n == 0) exit 1

    # Find min/max values from data
    vmin = vals[0]; vmax = vals[0]
    for (i = 1; i < n; i++) {
        if (vals[i] < vmin) vmin = vals[i]
        if (vals[i] > vmax) vmax = vals[i]
    }

    # Apply forced min/max if provided
    if (forced_min != "") vmin = forced_min + 0
    if (forced_max != "") vmax = forced_max + 0

    if (vmin == vmax) { vmin -= 1; vmax += 1 }
    vrange = vmax - vmin

    # Determine y-axis label width based on actual values
    s = sprintf("%.2f", vmax)
    label_w = length(s) + 1
    s = sprintf("%.2f", vmin)
    if (length(s) + 1 > label_w) label_w = length(s) + 1

    # Effective plot area
    plot_w = total_width - label_w - 2
    if (plot_w < 1) plot_w = 1
    plot_h = plot_height - 2
    if (plot_h < 3) plot_h = 3

    # Resample data to fit plot width
    if (n > plot_w) {
        for (i = 0; i < plot_w; i++) {
            idx = int(i * (n - 1) / (plot_w - 1) + 0.5)
            if (idx >= n) idx = n - 1
            sv[i] = vals[idx]
            st[i] = times[idx]
        }
        np = plot_w
    } else {
        for (i = 0; i < n; i++) {
            sv[i] = vals[i]
            st[i] = times[i]
        }
        np = n
    }

    # Scale values to row indices
    # Row 0 = top (vmax), row plot_h-1 = bottom (vmin)
    for (i = 0; i < np; i++) {
        scaled[i] = int((plot_h - 1) - (sv[i] - vmin) / vrange * (plot_h - 1) + 0.5)
        if (scaled[i] < 0) scaled[i] = 0
        if (scaled[i] >= plot_h) scaled[i] = plot_h - 1
    }

    # Initialize grid with spaces
    for (r = 0; r < plot_h; r++)
        for (c = 0; c < np; c++)
            grid[r, c] = " "

    # Plot first point
    grid[scaled[0], 0] = "╶"

    # Plot transitions between consecutive points
    for (i = 1; i < np; i++) {
        y0 = scaled[i]
        y1 = scaled[i - 1]

        if (y0 == y1) {
            grid[y0, i] = "─"
        } else if (y0 < y1) {
            grid[y0, i] = "╭"
            grid[y1, i] = "╯"
            for (r = y0 + 1; r < y1; r++)
                grid[r, i] = "│"
        } else {
            grid[y1, i] = "╮"
            grid[y0, i] = "╰"
            for (r = y1 + 1; r < y0; r++)
                grid[r, i] = "│"
        }
    }

    # Print chart rows
    for (r = 0; r < plot_h; r++) {
        val = vmax - (r / (plot_h - 1)) * vrange

        # Y-axis label (colored)
        printf "%s%" label_w ".2f%s", c_label, val, (c_label != "" ? reset : "")

        # Axis tick (colored)
        printf " %s┤%s", c_axis, (c_axis != "" ? reset : "")

        # Chart line (colored)
        if (c_line != "") printf "%s", c_line
        for (c = 0; c < np; c++)
            printf "%s", grid[r, c]
        if (c_line != "") printf "%s", reset
        printf "\n"
    }

    # X-axis border line
    printf "%" label_w "s", ""
    printf " %s┼", c_axis
    for (c = 0; c < np; c++)
        printf "─"
    if (c_axis != "") printf "%s", reset
    printf "\n"

    # X-axis time labels using subscript Unicode characters
    subs["0"] = "₀"; subs["1"] = "₁"; subs["2"] = "₂"; subs["3"] = "₃"
    subs["4"] = "₄"; subs["5"] = "₅"; subs["6"] = "₆"; subs["7"] = "₇"
    subs["8"] = "₈"; subs["9"] = "₉"; subs[":"] = "꞉"

    sample_lbl = st[0]
    lbl_len = length(sample_lbl)
    label_gap = 2

    max_labels = int(np / (lbl_len + label_gap))
    if (max_labels < 2) max_labels = 2
    if (max_labels > 7) max_labels = 7

    num_labels = max_labels
    if (np < num_labels) num_labels = np
    if (num_labels < 1) num_labels = 1

    # Build label line as array of single-char-width slots
    total_label_w = np + label_w + 2 + lbl_len + 1
    for (c = 0; c < total_label_w; c++)
        lbl_line[c] = " "

    last_end = -1
    for (li = 0; li < num_labels; li++) {
        if (num_labels == 1) col = 0
        else col = int(li * (np - 1) / (num_labels - 1))

        lbl = st[col]
        cur_len = length(lbl)

        pos = label_w + 2 + col - int(cur_len / 2)
        if (pos < 0) pos = 0

        if (pos <= last_end) continue

        for (k = 0; k < cur_len; k++) {
            ch = substr(lbl, k + 1, 1)
            if (ch in subs)
                lbl_line[pos + k] = subs[ch]
            else
                lbl_line[pos + k] = ch
        }
        last_end = pos + cur_len
    }

    # Print label line (colored)
    if (c_time != "") printf "%s", c_time
    line = ""
    for (c = 0; c < total_label_w; c++)
        line = line lbl_line[c]
    printf "%s", line
    if (c_time != "") printf "%s", reset
    printf "\n"
}
'
