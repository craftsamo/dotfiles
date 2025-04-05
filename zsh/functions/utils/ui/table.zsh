#!/usr/bin/env zsh

# Display data in a formatted table
function tum_table() {
  local col_count=$#
  local col_widths=()
  local headers=("$@")
  local data=()
  local line
 
  # Initialize width array with proper indexing
  for ((i=1; i<=col_count; i++)); do
    col_widths[$i]=${#headers[$i]}
  done
 
  # Read data rows from stdin and process widths
  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Add to data for later printing
    data+=("$line")

    # Split line and update column widths
    local -a columns
    columns=("${(@s/|/)line}")
    for ((i=1; i<=col_count && i<=${#columns[@]}; i++)); do
      if ((${#columns[$i]} > col_widths[$i])); then
        col_widths[$i]=${#columns[$i]}
      fi
    done
  done

  # Print header
  echo
  for ((i=1; i<=col_count; i++)); do
    printf "%-$((col_widths[i] + 2))s" "${headers[$i]}"
  done
  echo
 
  # Print separator line
  local sep=""
  for ((i=1; i<=col_count; i++)); do
    sep+=$(printf "%$(($col_widths[i] + 2))s" | tr ' ' '-')
  done
  echo "$sep"
 
  # Print data
  for line in "${data[@]}"; do
    local -a columns
    columns=("${(@s/|/)line}")
    for ((i=1; i<=col_count && i<=${#columns[@]}; i++)); do
      printf "%-$((col_widths[i] + 2))s" "${columns[$i]}"
    done
    echo
  done
}
