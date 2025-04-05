#!/usr/bin/env zsh

# Pause execution until user presses a key
function tum_pause() {
  local message="${1:-Press any key to continue...}"
  echo
  read -k1 -s -r "?$message"
  echo
}
