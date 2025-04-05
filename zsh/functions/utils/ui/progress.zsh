#!/usr/bin/env zsh

# Display a progress bar for long operations
function tum_progress_bar() {
  local percent=$1
  local width=${2:-40}
  local bar_char=${3:-"█"}
  local empty_char=${4:-"░"}

  # Calculate the number of filled/empty characters
  local filled=$((percent * width / 100))
  local empty=$((width - filled))

  # Build the bar
  local bar=""
  for ((i = 0; i < filled; i++)); do
    bar+="$bar_char"
  done
  for ((i = 0; i < empty; i++)); do
    bar+="$empty_char"
  done

  # Print the progress bar
  printf "\r[%s] %3d%%" "$bar" "$percent"

  # If 100%, add a newline
  [[ $percent -eq 100 ]] && echo
}

# Show a spinner animation during long operations
function tum_spinner() {
  local message="$1"
  local pid=$2 # PID to monitor
  local spin_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0

  # Wait for the process to complete
  while ps -p $pid &>/dev/null; do
    printf "\r${spin_chars[$i]} $message"
    i=$(((i + 1) % ${#spin_chars[@]}))
    sleep 0.1
  done
  printf "\r%-50s\r" " " # Clear the line
  wait $pid 2>/dev/null  # Properly wait for the process to avoid zombie
}
