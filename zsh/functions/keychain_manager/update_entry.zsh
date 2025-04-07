#!/usr/bin/env zsh

function update_entry() {
  tum_info "Update Keychain Entry"
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

  target_name=$(tum_select "Select keychain to update entry" "${names[@]}")
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
  unlock_keychain "$target_name"

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
  selected_entry=$(tum_select "Select entry to update" "${entries[@]}")
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

  # Display current metadata
  echo
  tum_info "Current Entry Details:"
  tum_separator
  cat "$metadata_file" | jq -r '
      to_entries | .[] | 
      "\(.key | ascii_upcase[0:1] + .[1:]): \(.value | if type == "string" then . else "None" end)"
    '
  echo

  # Get all properties from metadata
  local all_props=($(jq -r 'keys[]' "$metadata_file"))

  # Add "value" to the properties list if not already there
  if [[ ! " ${all_props[@]} " =~ " value " ]]; then
    all_props+=("value")
  fi

  # Select properties to update (default is "value")
  local props_to_update=($(tum_multiselect "Select properties to update" "${all_props[@]}"))
  if [[ ${#props_to_update[@]} -eq 0 ]]; then
    tum_warn "No properties selected for update."
    tum_pause
    return 1
  fi

  # Load current values from metadata
  local name=$(jq -r '.name // ""' "$metadata_file")
  local group=$(jq -r '.group // ""' "$metadata_file")
  local key_name=$(jq -r '.key_name // ""' "$metadata_file")
  local environment=$(jq -r '.environment // "develop"' "$metadata_file")
  local description=$(jq -r '.description // ""' "$metadata_file")
  local value=""

  # Try to get current password
  local current_value=$(security find-generic-password -a "$USER" -s "$selected_entry" -w "$target_kc" 2>/dev/null)

  # Process each selected property for update
  for prop in "${props_to_update[@]}"; do
    local current_val=""

    if [[ "$prop" == "value" ]]; then
      current_val="[MASKED]"
      tum_info "Current $prop: $current_val"

      # Check clipboard first
      if [[ -n "$(pbpaste)" ]]; then
        value=$(pbpaste)
        tum_info "Clipboard value detected"
        if ! tum_confirm "Use clipboard value?"; then
          value=""
        fi
      fi

      if [[ -z "$value" ]]; then
        value=$(tum_masked_input "Enter new secret value:")
      fi

      if [[ -z "$value" ]]; then
        tum_warn "No value provided, keeping existing secret value"
        value="$current_value"
      fi
    else
      current_val=$(jq -r ".$prop // \"\"" "$metadata_file")
      tum_info "Current $prop: $current_val"

      local new_val
      new_val=$(tum_input "Enter new $prop value (leave empty to keep current):")

      if [[ -n "$new_val" ]]; then
        # Update the variable based on property name
        case "$prop" in
        name) name="$new_val" ;;
        group) group="$new_val" ;;
        environment) environment="$new_val" ;;
        description) description="$new_val" ;;
        *)
          # Handle dynamic properties by updating JSON directly
          jq ".$prop = \"$new_val\"" "$metadata_file" >"${metadata_file}.tmp" && mv "${metadata_file}.tmp" "$metadata_file"
          ;;
        esac
      fi
    fi
  done

  # Generate updated key_name if name or group was changed
  if [[ " ${props_to_update[@]} " =~ " name " || " ${props_to_update[@]} " =~ " group " ]]; then
    if [[ -n "$group" ]]; then
      key_name="${group}_${name}"
    else
      key_name="${name}"
    fi
  fi

  # Get the timestamp for update
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Prepare updated JSON metadata
  local json_data
  json_data=$(
    cat <<EOJSON
{
  "name": "$name",
  "group": "$group",
  "key_name": "$key_name",
  "environment": "$environment",
  "updated_at": "$timestamp",
  "description": "$description"
}
EOJSON
  )

  # Preserve any additional custom fields from original metadata
  for prop in $(jq -r 'keys[]' "$metadata_file"); do
    if [[ "$prop" != "name" && "$prop" != "group" && "$prop" != "key_name" &&
      "$prop" != "environment" && "$prop" != "description" && "$prop" != "updated_at" ]]; then
      local prop_val=$(jq -r ".$prop" "$metadata_file")
      json_data=$(echo "$json_data" | jq --arg prop "$prop" --arg val "$prop_val" '. + {($prop): $val}')
    fi
  done

  # Validate JSON
  if ! echo "$json_data" | jq empty 2>/dev/null; then
    tum_error "Invalid JSON format"
    tum_pause
    return 1
  fi

  # Update the metadata file
  echo "$json_data" | jq '.' >"$metadata_file"

  # If key_name changed, need to create a new entry and delete the old one
  if [[ "$key_name" != "$selected_entry" && (" ${props_to_update[@]} " =~ " name " || " ${props_to_update[@]} " =~ " group ") ]]; then
    # Create new entry with the updated key_name
    security add-generic-password \
      -a "$USER" \
      -s "$key_name" \
      -w "${value:-$current_value}" \
      "$target_kc"

    # If successful, delete the old entry
    if [[ $? -eq 0 ]]; then
      security delete-generic-password -a "$USER" -s "$selected_entry" "$target_kc" &>/dev/null
      # Rename the metadata file
      mv "$metadata_file" "$metadata_dir/${key_name}.json"
      tum_success "Entry renamed from '$selected_entry' to '$key_name'"
    else
      tum_error "Failed to update entry name in keychain"
      tum_pause
      return 1
    fi
  elif [[ " ${props_to_update[@]} " =~ " value " ]]; then
    # Only update the value if needed
    security add-generic-password -a "$USER" -s "$selected_entry" -w "$value" -U "$target_kc" &>/dev/null
    if [[ $? -ne 0 ]]; then
      # If update fails, try delete and add approach
      security delete-generic-password -a "$USER" -s "$selected_entry" "$target_kc" &>/dev/null
      security add-generic-password -a "$USER" -s "$selected_entry" -w "$value" "$target_kc"
    fi
  fi

  local result=$?
  if [[ $result -eq 0 ]]; then
    tum_success "Entry successfully updated in keychain"
    tum_info "Metadata file: $metadata_dir/${key_name:-$selected_entry}.json"
  else
    tum_error "Failed to update entry in keychain"
  fi

  tum_pause
}
