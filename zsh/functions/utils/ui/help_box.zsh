#!/usr/bin/env zsh

# Display a help/tips box
function tum_help_box() {
  local title="$1"
  shift
  local tips=("$@")
  local title_display=" 💡 $title "

  # Helper function to estimate display width (accounting for CJK characters)
  function _estimate_width() {
    local string="$1"
    local width=0
    local char

    # Process each character
    for ((i = 0; i < ${#string}; i++)); do
      char="${string:$i:1}"

      # Check if it's likely a CJK character (very rough estimation)
      if [[ $(printf "%d" "'$char") -gt 127 ]]; then
        # Most CJK characters and emoji take double width
        width=$((width + 2))
      else
        width=$((width + 1))
      fi
    done

    echo $width
  }

  # Step 1: Find the max width needed for content
  local max_content_width=0
  for tip in "${tips[@]}"; do
    local tip_width=$(_estimate_width "$tip")
    if ((tip_width > max_content_width)); then
      max_content_width=$tip_width
    fi
  done

  # Step 2: Determine box dimensions
  local title_width=$(_estimate_width "$title_display")
  local content_width=$((max_content_width + 6)) # Add space for "• " and padding

  # Make sure box is wide enough for title
  if ((title_width + 10 > content_width)); then
    content_width=$((title_width + 10))
  fi

  # Step 3: Create borders
  # Top border with title
  local dash_left=5
  local dash_right=$((content_width - title_width - dash_left))

  echo -n "┌"
  printf '%*s' $dash_left | tr ' ' '─'
  echo -n "$title_display"
  printf '%*s' $dash_right | tr ' ' '─'
  echo "┐"

  # Content lines
  for tip in "${tips[@]}"; do
    local tip_display_width=$(_estimate_width "$tip")
    local right_padding=$((content_width - tip_display_width - 4)) # -4 for "• " and space

    echo -n "│ • $tip"
    printf '%*s' $right_padding | tr ' ' ' '
    echo " │"
  done

  # Bottom border
  echo -n "└"
  printf '%*s' $content_width | tr ' ' '─'
  echo "┘"
}
