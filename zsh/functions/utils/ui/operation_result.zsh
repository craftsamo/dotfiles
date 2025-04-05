#!/usr/bin/env zsh

# Show operation result with proper formatting
function tum_operation_result() {
  local operation=$1
  local result=$2
  local message=$3
  if [[ $result -eq 0 ]]; then
    tum_success "$operation: $message"
  else
    tum_error "$operation: $message"
  fi
}
