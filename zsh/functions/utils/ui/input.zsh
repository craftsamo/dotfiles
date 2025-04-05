#!/usr/bin/env zsh

# Function that takes user input as-is
function tum_input() {
  local prompt="${1:-Enter input: }"
  local input=""
  local char

  # Display prompt using stderr to prevent it being captured by command substitution
  echo -n "✏️  $prompt " >&2

  # Read input until Enter is pressed
  while IFS= read -rs -k1 char; do
    # Handle backspace (^H or ASCII 127)
    if [[ "$char" == $'\b' || "$char" == $'\177' ]]; then
      if ((${#input} > 0)); then
        input="${input%?}"   # Remove last char
        echo -n $'\b \b' >&2 # Erase character
      fi
    # Handle enter key (break the loop)
    elif [[ "$char" == $'\n' || "$char" == $'\r' ]]; then
      break
    else
      input+="$char"
      echo -n "$char" >&2 # Echo the character
    fi
  done

  echo >&2 # Add newline to stderr after input
  echo "$input"
}

# Function to receive masked user input (e.g., password input)
function tum_masked_input() {
  local prompt="${1:-Enter secret: }"
  local masked_input=""
  local char

  # Use stderr for prompt to prevent it being captured by command substitution
  echo -n "🔒 $prompt" >&2

  while IFS= read -rs -k1 char; do
    # Handle backspace (^H or ASCII 127)
    if [[ "$char" == $'\b' || "$char" == $'\177' ]]; then
      if ((${#masked_input} > 0)); then
        masked_input="${masked_input%?}" # Remove last char
        echo -n $'\b \b' >&2             # Erase asterisk
      fi
    # Handle enter key (break the loop)
    elif [[ "$char" == $'\n' || "$char" == $'\r' ]]; then
      break
    else
      masked_input+="$char"
      echo -n "*" >&2 # Show asterisk for each character
    fi
  done

  echo >&2 # Add newline to stderr after input
  echo "$masked_input"
}
