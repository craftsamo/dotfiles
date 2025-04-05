#!/usr/bin/env zsh

function tum_show_header() {
  local title="$1"
  local emoji="${2:-📋}" # Default emoji is a clipboard, but can be overridden
  clear
  echo "╭─────────────────────────────────────────╮"
  printf "│ %-38s │\n" "$emoji $title"
  echo "╰─────────────────────────────────────────╯"
  echo
}
