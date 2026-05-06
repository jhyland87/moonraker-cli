BEGIN {
    reset = "\033[0m"
    if (show_legend == "") show_legend = 1
    if (c_label != "") c_label = "\033[" c_label "m"
    if (c_time  != "") c_time  = "\033[" c_time  "m"
    if (c_axis  != "") c_axis  = "\033[" c_axis  "m"

    # Parse color and name lists
    split(color_list, raw_colors, "|")
    split(name_list, names, "|")
    for (s = 1; s <= num_series; s++) {
        if (raw_colors[s] != "")
            colors[s] = "\033[" raw_colors[s] "m"
        else
            colors[s] = ""
    }
}
{
    if (NF < 3) next
    s = $1 + 1  # 1-indexed series
    idx = count[s] + 0  # force numeric so the array key is "0", not ""
    series_times[s, idx] = $2
    series_vals[s, idx] = $3 + 0
    count[s] = idx + 1
}
END {
    # Find global min/max across all series
    first = 1
    for (s = 1; s <= num_series; s++) {
        for (i = 0; i < count[s]; i++) {
            v = series_vals[s, i]
            if (first) { vmin = v; vmax = v; first = 0 }
            if (v < vmin) vmin = v
            if (v > vmax) vmax = v
        }
    }

    if (forced_min != "") vmin = forced_min + 0
    if (forced_max != "") vmax = forced_max + 0
    if (vmin == vmax) { vmin -= 1; vmax += 1 }
    vrange = vmax - vmin

    # Determine y-axis label width
    s_str = sprintf("%.2f", vmax)
    label_w = length(s_str) + 1
    s_str = sprintf("%.2f", vmin)
    if (length(s_str) + 1 > label_w) label_w = length(s_str) + 1

    # Effective plot area
    plot_w = total_width - label_w - 2
    if (plot_w < 1) plot_w = 1
    plot_h = plot_height - 2
    if (plot_h < 3) plot_h = 3

    # Resample each series to fit plot_w
    for (s = 1; s <= num_series; s++) {
        n = count[s]
        if (n == 0) { np[s] = 0; continue }
        if (n > plot_w) {
            for (i = 0; i < plot_w; i++) {
                idx = int(i * (n - 1) / (plot_w - 1) + 0.5)
                if (idx >= n) idx = n - 1
                sv[s, i] = series_vals[s, idx]
                st[s, i] = series_times[s, idx]
            }
            np[s] = plot_w
        } else {
            for (i = 0; i < n; i++) {
                sv[s, i] = series_vals[s, i]
                st[s, i] = series_times[s, i]
            }
            np[s] = n
        }

        # Scale values to row indices
        for (i = 0; i < np[s]; i++) {
            scaled[s, i] = int((plot_h - 1) - (sv[s, i] - vmin) / vrange * (plot_h - 1) + 0.5)
            if (scaled[s, i] < 0) scaled[s, i] = 0
            if (scaled[s, i] >= plot_h) scaled[s, i] = plot_h - 1
        }
    }

    # Initialize grid: each cell has a character and a series index (0 = none)
    for (r = 0; r < plot_h; r++) {
        for (c = 0; c < plot_w; c++) {
            grid_ch[r, c] = " "
            grid_s[r, c] = 0
        }
    }

    # Plot each series (later series draw on top)
    for (s = 1; s <= num_series; s++) {
        if (np[s] == 0) continue

        # First point
        grid_ch[scaled[s, 0], 0] = "╶"
        grid_s[scaled[s, 0], 0] = s

        for (i = 1; i < np[s]; i++) {
            y0 = scaled[s, i]
            y1 = scaled[s, i - 1]

            if (y0 == y1) {
                grid_ch[y0, i] = "─"
                grid_s[y0, i] = s
            } else if (y0 < y1) {
                grid_ch[y0, i] = "╭"
                grid_s[y0, i] = s
                grid_ch[y1, i] = "╯"
                grid_s[y1, i] = s
                for (r = y0 + 1; r < y1; r++) {
                    grid_ch[r, i] = "│"
                    grid_s[r, i] = s
                }
            } else {
                grid_ch[y1, i] = "╮"
                grid_s[y1, i] = s
                grid_ch[y0, i] = "╰"
                grid_s[y0, i] = s
                for (r = y1 + 1; r < y0; r++) {
                    grid_ch[r, i] = "│"
                    grid_s[r, i] = s
                }
            }
        }
    }

    # Legend box dimensions
    max_name_len = 0
    for (s = 1; s <= num_series; s++) {
        nl = length(names[s])
        if (nl > max_name_len) max_name_len = nl
    }
    legend_inner_w = 5 + max_name_len  # " ─── Name "
    legend_w = legend_inner_w + 2       # + left/right border
    legend_h = num_series + 2           # + top/bottom border

    # Position legend at top-right of plot area
    legend_col = plot_w - legend_w
    legend_row = 0
    if (legend_col < 0) legend_col = 0

    # Overlay legend onto grid (skipped when show_legend=0)
    # We store legend content separately so we can print it with correct colors
    if (show_legend) for (r = 0; r < legend_h; r++) {
        for (c = 0; c < legend_w; c++) {
            gr = legend_row + r
            gc = legend_col + c
            if (gr >= plot_h || gc >= plot_w) continue

            if (r == 0) {
                # Top border
                if (c == 0) ch = "┌"
                else if (c == legend_w - 1) ch = "┐"
                else ch = "─"
                grid_ch[gr, gc] = ch
                grid_s[gr, gc] = -1  # axis color
            } else if (r == legend_h - 1) {
                # Bottom border
                if (c == 0) ch = "└"
                else if (c == legend_w - 1) ch = "┘"
                else ch = "─"
                grid_ch[gr, gc] = ch
                grid_s[gr, gc] = -1
            } else if (c == 0 || c == legend_w - 1) {
                # Side borders
                grid_ch[gr, gc] = "│"
                grid_s[gr, gc] = -1
            } else {
                # Inner content: " ─── Name "
                si = r  # series index (1-based, since r starts at 1 for inner rows)
                inner_pos = c - 1  # 0-based position inside the border
                # Build the inner string: " ─── Name" padded to legend_inner_w
                # Positions: 0=space, 1-3=line chars, 4=space, 5+=name chars
                if (inner_pos == 0) {
                    grid_ch[gr, gc] = " "
                    grid_s[gr, gc] = -1
                } else if (inner_pos >= 1 && inner_pos <= 3) {
                    grid_ch[gr, gc] = "─"
                    grid_s[gr, gc] = si  # series color
                } else if (inner_pos == 4) {
                    grid_ch[gr, gc] = " "
                    grid_s[gr, gc] = -1
                } else {
                    name_idx = inner_pos - 5
                    nm = names[si]
                    if (name_idx < length(nm)) {
                        grid_ch[gr, gc] = substr(nm, name_idx + 1, 1)
                        grid_s[gr, gc] = si  # series color
                    } else {
                        grid_ch[gr, gc] = " "
                        grid_s[gr, gc] = -1
                    }
                }
            }
        }
    }

    # Print chart rows
    for (r = 0; r < plot_h; r++) {
        val = vmax - (r / (plot_h - 1)) * vrange
        printf "%s%" label_w ".2f%s", c_label, val, (c_label != "" ? reset : "")
        printf " %s┤%s", c_axis, (c_axis != "" ? reset : "")

        prev_color = ""
        for (c = 0; c < plot_w; c++) {
            ch = grid_ch[r, c]
            si = grid_s[r, c]

            if (si == -1) {
                # Axis/legend border color
                need = c_axis
            } else if (si > 0) {
                need = colors[si]
            } else {
                need = ""
            }

            if (need != prev_color) {
                if (prev_color != "") printf "%s", reset
                if (need != "") printf "%s", need
                prev_color = need
            }
            printf "%s", ch
        }
        if (prev_color != "") printf "%s", reset
        printf "\n"
    }

    # X-axis border line
    printf "%" label_w "s", ""
    printf " %s┼", c_axis
    for (c = 0; c < plot_w; c++)
        printf "─"
    if (c_axis != "") printf "%s", reset
    printf "\n"

    # X-axis time labels (use first series with data for timestamps)
    ref_s = 1
    for (s = 1; s <= num_series; s++) {
        if (np[s] > 0) { ref_s = s; break }
    }

    subs["0"] = "₀"; subs["1"] = "₁"; subs["2"] = "₂"; subs["3"] = "₃"
    subs["4"] = "₄"; subs["5"] = "₅"; subs["6"] = "₆"; subs["7"] = "₇"
    subs["8"] = "₈"; subs["9"] = "₉"; subs[":"] = "꞉"

    sample_lbl = st[ref_s, 0]
    lbl_len = length(sample_lbl)
    label_gap = 2

    max_labels = int(np[ref_s] / (lbl_len + label_gap))
    if (max_labels < 2) max_labels = 2
    if (max_labels > 7) max_labels = 7

    num_labels = max_labels
    ref_np = np[ref_s]
    if (ref_np < num_labels) num_labels = ref_np
    if (num_labels < 1) num_labels = 1

    total_label_w = ref_np + label_w + 2 + lbl_len + 1
    for (c = 0; c < total_label_w; c++)
        lbl_line[c] = " "

    last_end = -1
    for (li = 0; li < num_labels; li++) {
        if (num_labels == 1) col = 0
        else col = int(li * (ref_np - 1) / (num_labels - 1))

        lbl = st[ref_s, col]
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

    if (c_time != "") printf "%s", c_time
    line = ""
    for (c = 0; c < total_label_w; c++)
        line = line lbl_line[c]
    printf "%s", line
    if (c_time != "") printf "%s", reset
    printf "\n"
}
