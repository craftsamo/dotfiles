#!/usr/bin/env zsh

# Create a consistent fzf menu with proper wrapping and styling
function tum_select() {
  local prompt="$1"
  shift
  printf "%s\n" "$@" | fzf --prompt="$prompt > " --height=~50% --layout=reverse --border
}

# Create a multi-select menu where users can pick multiple items
function tum_multiselect() {
  local prompt="$1"
  shift
  printf "%s\n" "$@" | fzf --prompt="$prompt > " --multi --height=~50% --layout=reverse --border
}
