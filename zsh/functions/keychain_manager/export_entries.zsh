#!/usr/bin/env zsh

function export_entries() {
  tum_info "Export Keychain Entries"
  tum_separator

  # Select target keychain
  local custom=($(get_keychains "path"))
  local names=($(get_keychains "name"))

  if [[ ${#custom[@]} -eq 0 ]]; then
    tum_error "No available custom keychains found."
    tum_pause
    return 1
  fi

  # Let user select a keychain
  local target_name
  local target_kc

  target_name=$(tum_select "Select keychain to export entries from" "${names[@]}")
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
  unlock_keychain "$target_name"

  # Get all services from the keychain
  local services
  services=($(security dump-keychain -d "$target_kc" 2>/dev/null |
    grep -oE '"svce"[[:space:]]*<blob>="[^"]*"' | sed -E 's/"svce"[[:space:]]*<blob>="(.*)"/\1/'))

  if [[ ${#services[@]} -eq 0 ]]; then
    tum_warn "No registered entries found in this keychain."
    tum_pause
    return 0
  fi

  # Check for metadata
  local metadata_dir="$HOME/.config/zsh/functions/keychain_manager/metadatas/$target_name"

  # Select export format
  local format=$(tum_select "Select export format" "env" "json")
  if [[ -z "$format" ]]; then
    tum_warn "Operation canceled."
    tum_pause
    return 1
  fi

  # Select export location
  local location=$(tum_select "Select export location" "Current directory" "Specify directory")
  if [[ -z "$location" ]]; then
    tum_warn "Operation canceled."
    tum_pause
    return 1
  fi

  local target_dir
  if [[ "$location" == "Current directory" ]]; then
    target_dir="$PWD"
  else
    tum_info "Enter target directory path:"
    read -r target_dir

    if [[ ! -d "$target_dir" ]]; then
      if tum_confirm "Directory doesn't exist. Create it?"; then
        mkdir -p "$target_dir"
        if [[ $? -ne 0 ]]; then
          tum_error "Failed to create directory: $target_dir"
          tum_pause
          return 1
        fi
      else
        tum_warn "Operation canceled."
        tum_pause
        return 1
      fi
    fi
  fi

  # Select entries to export
  local selected_entries=()
  selected_entries=($(tum_multiselect "Select entries to export" "${services[@]}"))

  if [[ ${#selected_entries[@]} -eq 0 ]]; then
    tum_warn "No entries selected for export."
    tum_pause
    return 1
  fi

  # Determine filename based on format
  local filename
  if [[ "$format" == "env" ]]; then
    filename=".env"
  else
    filename="keychain_export.json"
  fi

  local filepath="$target_dir/$filename"

  # Initialize for JSON format if creating new file
  if [[ "$format" == "json" && ! -f "$filepath" ]]; then
    echo "{}" >"$filepath"
  fi

  tum_info "Exporting entries to $filepath"

  local entries_exported=0

  # Process each selected entry
  for service in "${selected_entries[@]}"; do
    # Get value from keychain
    local value=$(security find-generic-password -a "$USER" -s "$service" -w "$target_kc" 2>/dev/null)
    if [[ -z "$value" ]]; then
      tum_warn "Could not retrieve value for $service. Skipping."
      continue
    fi

    # Get key_name from metadata if available
    local key_name="$service"
    local metadata_file="$metadata_dir/${service}.json"

    if [[ -f "$metadata_file" ]]; then
      local metadata_key_name=$(jq -r '.key_name // ""' "$metadata_file")
      if [[ -n "$metadata_key_name" && "$metadata_key_name" != "null" ]]; then
        key_name="$metadata_key_name"
      fi
    fi

    # Convert key_name to uppercase
    key_name="${key_name:u}"

    # Export based on format
    if [[ "$format" == "env" ]]; then
      # Check if key already exists in .env file
      if [[ -f "$filepath" ]] && grep -q "^$key_name=" "$filepath"; then
        tum_warn "Key $key_name already exists in $filepath. Skipping."
        continue
      fi

      # Append to .env file
      echo "$key_name=$value" >>"$filepath"

    else # JSON format
      # Update JSON file using temporary file to avoid corruption
      local temp_file=$(mktemp)

      if [[ -f "$metadata_file" ]]; then
        # Extract metadata as JSON
        local metadata_content=$(cat "$metadata_file")
        # Add the value to metadata
        local entry_data=$(echo "$metadata_content" | jq --arg val "$value" '. + {"value": $val}')
        # Add the entry to the export file
        jq --arg key "$service" --argjson data "$entry_data" '. + {($key): $data}' "$filepath" >"$temp_file"
      else
        # No metadata, just add service and value
        jq --arg key "$service" --arg val "$value" '. + {($key): {"value": $val}}' "$filepath" >"$temp_file"
      fi
      mv "$temp_file" "$filepath"
    fi

    ((entries_exported++))
  done

  if [[ $entries_exported -gt 0 ]]; then
    tum_success "Successfully exported $entries_exported entries to $filepath"
  else
    tum_warn "No entries were exported."
  fi

  tum_pause
}
