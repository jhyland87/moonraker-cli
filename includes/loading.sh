#!/usr/bin/env bash

# show_loading - Display a neat loading animation in the terminal
# Usage:
#   show_loading                    # Default spinner style (continuous)
#   show_loading "Processing..."     # With custom message
#   show_loading -s dots             # Different style (spinner|dots|braille|bars|pulse|hexagram)
#   show_loading -s braille -m "Loading data" -c 220
#   show_loading -s braille -m "Processing..." -f 3  # Show single frame at index 3
#   show_loading -s hexagram -m "Transforming..."  # Yijing hexagram symbols
#
# Options:
#   -s, --style STYLE    Animation style: spinner, dots, braille, bars, pulse, hexagram (default: spinner)
#   -m, --message MSG    Custom message to display (default: "Loading")
#   -c, --color COLOR    ANSI color code (default: auto-rotating colors)
#   -i, --interval SEC   Animation frame interval in seconds (default: 0.1)
#   -f, --frame NUM      Show only one frame at the specified index (0-based)
#   -h, --help           Show this help message
#
# The function runs until interrupted (Ctrl+C) or until you call stop_loading
# When -f/--frame is used, it shows a single frame and returns immediately
# Example:
#   show_loading -s braille -m "Fetching data..." &
#   LOADER_PID=$!
#   # ... do work ...
#   stop_loading $LOADER_PID
#
# Single frame example:
#   frame=0
#   until nc -z localhost 8080 2>/dev/null; do
#     let frame++
#     show_loading -s braille -m "Processing..." -f $frame
#     sleep 0.1
#   done
function show_loading {
  local style="spinner"
  local message="Loading"
  local color=""
  local interval=0.1
  local frame=""
  local opts=("$@")

  # Get the directory where this script is located
  local cwd=$(dirname "${BASH_SOURCE[0]}")

  # Parse arguments
  for ((i=0; i<${#opts[@]}; i++)); do
    case "${opts[$i]}" in
      -s|--style)
        [[ "${opts[$((i+1))]}" != "" ]] && style="${opts[$((i+1))]}" && ((i++))
        ;;
      -m|--message)
        [[ "${opts[$((i+1))]}" != "" ]] && message="${opts[$((i+1))]}" && ((i++))
        ;;
      -c|--color)
        [[ "${opts[$((i+1))]}" != "" ]] && color="${opts[$((i+1))]}" && ((i++))
        ;;
      -i|--interval)
        [[ "${opts[$((i+1))]}" != "" ]] && interval="${opts[$((i+1))]}" && ((i++))
        ;;
      -f|--frame)
        [[ "${opts[$((i+1))]}" != "" ]] && frame="${opts[$((i+1))]}" && ((i++))
        ;;
      -h|--help)
        echo "Usage: show_loading [OPTIONS]"
        echo "Options:"
        echo "  -s, --style STYLE    Animation style (spinner|dots|braille|bars|pulse|hexagram)"
        echo "  -m, --message MSG    Custom message"
        echo "  -c, --color COLOR    ANSI color code"
        echo "  -i, --interval SEC   Frame interval (default: 0.1)"
        echo "  -f, --frame NUM      Show single frame at index (0-based)"
        echo "  -h, --help           Show this help"
        return 0
        ;;
    esac
  done

  # Define animation frames for different styles
  declare -a spinner_frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  declare -a dots_frames=('⠁' '⠂' '⠄' '⠈' '⠐' '⠠' '⡀' '⢀' '⡠' '⡐' '⡈' '⡄' '⡂' '⡁')
  declare -a braille_frames=('⡏' '⠟' '⠻' '⢹' '⣸' '⣴' '⣦' '⣇')
  declare -a bars_frames=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' '▇' '▆' '▅' '▄' '▃' '▂')
	declare -a pulse_frames=('●' '⬮' '●' '⬬' '●' '⬯' '◯' '⬭' '◯' '⬮' '●' '⬬' '●' '⬯' '◯' '⬭')
	declare -a wheel_frames=('◴' '◷' '◶' '◵')
	declare -a arrow_frames=('➩' '➪' '➫' '➬' '➭' '➮' '➯')
	declare -a square_frames=( '⿹' '⿸' '⿺' '⿶' '⿷' '⿵' '⿴')
	# Yijing Hexagram Symbols - creates a transformation/change animation
	# Selected hexagrams that create visual flow: Creative → Receptive → Difficulty → Waiting → Progress → Completion
	declare -a hexagram_frames=('䷀' '䷁' '䷂' '䷄' '䷊' '䷋' '䷌' '䷍' '䷎' '䷏' '䷐' '䷑' '䷒' '䷓' '䷔' '䷕' '䷖' '䷗' '䷘' '䷙' '䷚' '䷛' '䷜' '䷝' '䷞' '䷟' '䷠' '䷡' '䷢' '䷣' '䷤' '䷥' '䷦' '䷧' '䷨' '䷩' '䷪' '䷫' '䷬' '䷭' '䷮' '䷯' '䷰' '䷱' '䷲' '䷳' '䷴' '䷵' '䷶' '䷷' '䷸' '䷹' '䷺' '䷻' '䷼' '䷽' '䷾' '䷿')
	# ⏇\n⏆\n⏆\n⏆\n⏆\n⏈
	# echo -e "⏇ A\n⏆ B\n⏆ C\n⏆ D\n⏆ E\n⏈ F"
	# echo -e "A ⏇\nB ⏆\nC ⏆\nD ⏆\nE ⏆\nF ⏈"

  # Select frames based on style
  local frames_var="${style}_frames"
  local -n frames="$frames_var"

  # Fallback to spinner if style not found
  if [[ -z "${frames[@]}" ]]; then
    frames=("${spinner_frames[@]}")
    style="spinner"
  fi

  # Color handling
  local color_code=""
  local color_idx=0
  if [[ -n "$color" ]]; then
    color_code="\e[38;5;${color}m"
  else
    # Auto-rotating colors from loading-colors.list if available
    if [[ -f "${cwd}/data/loading-colors.list" ]]; then
      readarray -t colors < "${cwd}/data/loading-colors.list"
    else
      # Fallback colors
      colors=(220 214 208 202 196 160 124 88 52)
    fi
  fi

  local frame_count=${#frames[@]}

  # If frame is specified, show single frame and return
  if [[ -n "$frame" ]]; then
    # Convert frame to integer and wrap around if needed
    local idx=$((frame % frame_count))
    local current_frame="${frames[$idx]}"

    # Calculate color index based on frame
    if [[ -z "$color" ]]; then
      color_idx=$((frame % ${#colors[@]}))
    fi

    if [[ -n "$color" ]]; then
      printf "\r%s%s\e[0m %s" "$color_code" "$current_frame" "$message"
    else
      local current_color="${colors[$color_idx]}"
      printf "\r\e[38;5;%s;1m%s\e[0m %s" "$current_color" "$current_frame" "$message"
    fi
    return 0
  fi

  # Continuous animation mode
  local idx=0
  local cleanup_done=0

  # Cleanup function
  cleanup_loading() {
    if [[ $cleanup_done -eq 0 ]]; then
      cleanup_done=1
      tput cnorm 2>/dev/null
      printf "\r%$(tput cols)s\r" " " 2>/dev/null
    fi
  }

  trap cleanup_loading EXIT INT TERM
  tput civis 2>/dev/null

  # Animation loop
  while true; do
    local current_frame="${frames[$idx]}"

    if [[ -n "$color" ]]; then
      printf "\r%s%s\e[0m %s" "$color_code" "$current_frame" "$message"
    else
      local current_color="${colors[$color_idx]}"
      printf "\r\e[38;5;%s;1m%s\e[0m %s" "$current_color" "$current_frame" "$message"

      # Rotate color every few frames
      if [[ $(($idx % 3)) -eq 0 ]]; then
        color_idx=$(( (color_idx + 1) % ${#colors[@]} ))
      fi
    fi

    idx=$(( (idx + 1) % frame_count ))
    sleep "$interval"
  done
}

# stop_loading - Stop a running loading animation
# Usage: stop_loading [PID]
# If no PID is provided, tries to find the most recent show_loading process
function stop_loading {
  local pid="${1:-}"

  if [[ -z "$pid" ]]; then
    # Try to find show_loading process
    pid=$(pgrep -f "show_loading" | head -1)
  fi

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    tput cnorm 2>/dev/null
    printf "\r%$(tput cols)s\r" " "
    return 0
  else
    echo "No loading animation process found" >&2
    return 1
  fi
}

