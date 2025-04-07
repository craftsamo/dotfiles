#!/usr/bin/env zsh

function get_entry() {
  tum_info "Get Keychain Entry"
  tum_separator

  # Select target keychain (using get_keychains function)
  local custom=($(get_keychains "path"))
  local names=($(get_keychains "name"))

  if [[ ${#custom[@]} -eq 0 ]]; then
    tum_error "No available custom keychains found."
    tum_pause
    return 1
  fi

  # Let user select a keychain
  local target_idx
  local target_name
  local target_kc

  target_name=$(tum_select "Select keychain to view entry" "${names[@]}")
  if [[ -z "$target_name" ]]; then
    tum_warn "Operation canceled."
    tum_pause
    return 1
  fi

  # Find corresponding path
  local i=1
  for name in "${names[@]}"; do
    if [[ "$name" == "$target_name" ]]; then
      target_kc="${custom[$i]}"
      break
    fi
    ((i++))
  done

  # Check if keychain is locked and unlock if necessary
  local keychain_name=$(basename "$target_kc" .keychain-db)

  # Use the unlock_keychain function instead of reimplementing the logic
  unlock_keychain "$keychain_name"

  # Check if metadata directory exists
  local metadata_dir="$HOME/.config/zsh/functions/keychain_manager/metadatas/$keychain_name"
  if [[ ! -d "$metadata_dir" ]]; then
    tum_error "No entries found for keychain $target_name"
    tum_pause
    return 1
  fi

  # Get list of entries (JSON files from metadata directory)
  local entries=()
  local entry_files=($metadata_dir/*.json)

  # Skip information.json file and build entry list from metadata filenames
  for entry_file in "${entry_files[@]}"; do
    local basename_file=$(basename "$entry_file")
    if [[ "$basename_file" != "information.json" ]]; then
      local entry_name="${basename_file%.json}"
      entries+=("$entry_name")
    fi
  done

  if [[ ${#entries[@]} -eq 0 ]]; then
    tum_error "No entries found in keychain $target_name"
    tum_pause
    return 1
  fi

  # Let user select an entry
  local selected_entry
  selected_entry=$(tum_select "Select entry to retrieve" "${entries[@]}")
  if [[ -z "$selected_entry" ]]; then
    tum_warn "No entry selected."
    tum_pause
    return 1
  fi

  # Get metadata for the selected entry
  local metadata_file="$metadata_dir/${selected_entry}.json"
  if [[ ! -f "$metadata_file" ]]; then
    tum_error "Metadata file not found: $metadata_file"
    tum_pause
    return 1
  fi

  # Display metadata
  echo
  tum_info "Entry Details:"
  tum_separator
  cat "$metadata_file" | jq -r '
      to_entries | .[] | 
      "\(.key | ascii_upcase[0:1] + .[1:]): \(.value | if type == "string" then . else "None" end)"
    '

  secret_value=$(security find-generic-password -a "$USER" -s "$selected_entry" -w "$target_kc" 2>/dev/null)

  if [[ $? -ne 0 ]]; then
    echo
    tum_error "Failed to retrieve secret value from keychain."
  else
    echo
    tum_info "Secret Value: $secret_value"
    echo
    if tum_confirm "Show actual value?"; then
      tum_info "Secret Value (SENSITIVE): $secret_value"
      echo

      if tum_confirm "Copy to clipboard?"; then
        echo -n "$secret_value" | pbcopy
        tum_success "Value copied to clipboard"
      fi
    fi
  fi

  tum_pause
}
