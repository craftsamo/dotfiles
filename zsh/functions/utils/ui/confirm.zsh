#!/usr/bin/env zsh

function tum_confirm() {
  local prompt="${1:-Are you sure?}"
  local default="${2:-n}" # Default can be 'y' or 'n'
  local response=""

  local prompt_symbol
  if [[ "$default" == "y" ]]; then
    prompt_symbol="[Y/n]"
  else
    prompt_symbol="[y/N]"
  fi

  # Temporarily switch to a more interactive mode for proper input
  local old_state=$(stty -g </dev/tty 2>/dev/null)
  zle -I                          # This tells ZLE we're doing interactive input
  stty echo </dev/tty 2>/dev/null # Make sure terminal is echoing characters

  # Display the prompt
  printf "⚠️  %s %s " "$prompt" "$prompt_symbol"

  # Read user input with a visible cursor
  read -r response </dev/tty
  echo

  # Restore terminal state
  stty "$old_state" </dev/tty 2>/dev/null

  # Convert response to lowercase for comparison
  response=${response:l}

  # Return true for yes, false for no
  [[ -z "$response" ]] && response=$default
  [[ "$response" == "y" || "$response" == "yes" ]]
}
