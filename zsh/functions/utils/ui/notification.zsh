#!/usr/bin/env zsh

# Display notification with optional sound
function tum_notify() {
  local message="$1"
  local sound=${2:-false} # true/false to play a notification sound

  tum_info "$message"

  if [[ "$sound" == "true" ]]; then
    # Use Terminal bell
    echo -e "\a"
  fi
}
