#!/usr/bin/env zsh

# Display message with status icon
function tum_message() {
  local icon="$1"
  local message="$2"
  printf "${icon} ${message}\n"
}

# Display success message
function tum_success() {
  tum_message "✅" "$1"
}

# Display error message
function tum_error() {
  tum_message "❌" "$1"
}

# Display warning message
function tum_warning() {
  tum_message "⚠️ " "$1"
}

# Display info message
function tum_info() {
  tum_message "ℹ️ " "$1"
}
