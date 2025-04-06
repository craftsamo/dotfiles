#!/usr/bin/env zsh

function list_keychains() {
  tum_info "Custom Keychain List"
  tum_separator

  # Get custom keychain paths using the get_keychains utility
  local keychain_paths=($(get_keychains path))

  # If no custom keychains exist
  if [[ ${#keychain_paths[@]} -eq 0 ]]; then
    echo -e "\n※ No custom keychains found"
    tum_pause
    return 0
  fi

  # Prepare headers for the table
  local headers=("Created At" "Name" "Locked" "Has Password" "Password Entry")

  # Create a temporary file to store table data
  local tmp_data=$(mktemp)

  for keychain_path in "${keychain_paths[@]}"; do
    # Extract keychain name from path
    local keychain_name=$(basename "$keychain_path" | sed 's/\.keychain\(-db\)\{0,1\}$//')

    # Path to the metadata JSON file
    local metadata_dir="$HOME/.config/zsh/functions/keychain_manager/metadatas/${keychain_name}/information.json"

    # Check if metadata file exists
    if [[ ! -f "$metadata_file" ]]; then
      continue
    fi

    # Extract information from JSON file
    local created_at=$(jq -r '.created_at // "Unknown"' "$metadata_file")
    local has_password=$(jq -r '.has_password // false' "$metadata_file")
    local password_entry=$(jq -r '.password_keychain_entry // "None"' "$metadata_file")

    # Check if the keychain is currently locked
    local locked_status="Unknown"
    if [[ -f "$keychain_path" ]]; then
      if security show-keychain-info "$keychain_path" &>/dev/null; then
        locked_status="No"
      else
        locked_status="Yes"
      fi
    else
      locked_status="File Missing"
    fi

    # Format has_password for display
    local has_password_display
    if [[ "$has_password" == "true" ]]; then
      has_password_display="Yes"
    else
      has_password_display="No"
    fi

    # Format password_entry for display
    if [[ "$password_entry" == "null" ]]; then
      password_entry="None"
    fi

    # Add row to data file with | as column separator
    echo "${created_at}|${keychain_name}|${locked_status}|${has_password_display}|${password_entry}" >>"$tmp_data"
  done

  # Display the table using tum_table by passing headers as arguments
  # and piping the data file content to stdin
  tum_table "${headers[@]}" <"$tmp_data"

  # Remove temporary file
  rm -f "$tmp_data"
}
