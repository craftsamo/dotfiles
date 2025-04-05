#!/usr/bin/env zsh

# Display countdown timer (useful before returning to menus)
function tum_countdown() {
  local seconds="${1:-3}"
  local message="${2:-Returning to menu in}"

  echo
  for ((i = seconds; i > 0; i--)); do
    printf "\r$message $i..."
    sleep 1
  done
  printf "\r%-50s\r" " " # Clear the line
}
