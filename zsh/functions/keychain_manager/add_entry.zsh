#!/usr/bin/env zsh

function add_entry() {
  tum_info "Add Keychain Entry"
  tum_separator
  echo

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

  target_name=$(tum_select "Select keychain to add entry" "${names[@]}")
  if [[ -z "$target_name" ]]; then
    tum_warn "Operation canceled."
    tum_pause
    return 1
  fi

  # Find corresponding path
  local i=1

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
  local keychain_status=$(security show-keychain-info "$target_kc" 2>&1)

  if [[ $? -ne 0 && "$keychain_status" == *"The specified keychain could not be found."* ]]; then
    tum_error "Keychain not found: $target_kc"
    tum_pause
    return 1
  elif [[ $? -ne 0 && "$keychain_status" == *"SecKeychainGetStatus"* ]]; then
    tum_warning "Keychain $target_name is locked. Attempting to unlock..."

    # Try to get stored password from login keychain
    local stored_password
    stored_password=$(security find-generic-password -a "$USER" -s "CustomKeychainPassword_${keychain_name}" -w login.keychain 2>/dev/null)

    if [[ $? -eq 0 && -n "$stored_password" ]]; then
      # Unlock with stored password
      security unlock-keychain -p "$stored_password" "$target_kc"
      if [[ $? -ne 0 ]]; then
        tum_error "Failed to unlock keychain with stored password."
        # Ask for password manually
        local manual_password=$(tum_masked_input "Enter password for keychain '$target_name':")
        security unlock-keychain -p "$manual_password" "$target_kc"
        if [[ $? -ne 0 ]]; then
          tum_error "Failed to unlock keychain. Cannot proceed."
          tum_pause
          return 1
        fi
      else
        tum_success "Keychain unlocked successfully using stored password."
      fi
    else
      # No stored password, ask for it
      local manual_password=$(tum_masked_input "Enter password for keychain '$target_name':")
      security unlock-keychain -p "$manual_password" "$target_kc"
      if [[ $? -ne 0 ]]; then
        tum_error "Failed to unlock keychain. Cannot proceed."
        tum_pause
        return 1
      else
        tum_success "Keychain unlocked successfully."
      fi
    fi
  fi

  # Select environment
  local env_choice
  env_choice=$(tum_select "Select environment" "develop" "production")
  if [[ -z "$env_choice" ]]; then
    env_choice="develop"
  fi

  # Initialize variables
  local group=""
  local name=""
  local value=""
  local description=""

  # Input: name (required)
  while true; do
    name=$(tum_input "Enter name (required):")
    if [[ -n "$name" ]]; then
      break
    else
      tum_error "Name is required"
    fi
  done

  # Input: group (optional)
  group=$(tum_input "Enter group name (optional):")

  # Input: value (required)
  while true; do
    # Check clipboard first
    if [[ -n "$(pbpaste)" ]]; then
      value=$(pbpaste)
      tum_info "Clipboard value detected: $value"
      if ! tum_confirm "Use clipboard value?"; then
        value=""
      fi
    fi

    if [[ -z "$value" ]]; then
      value=$(tum_masked_input "Enter secret value (required):")
    fi

    if [[ -n "$value" ]]; then
      break
    else
      tum_error "Secret value is required"
    fi
  done

  # Input: description (optional)
  description=$(tum_input "Enter description (optional):")

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Generate key_name
  local key_name_generated
  if [[ -n "$group" ]]; then
    key_name_generated="${group}_${name}"
  else
    key_name_generated="${name}"
  fi

  # Create JSON metadata
  local json_data
  json_data=$(
    cat <<EOJSON
{
  "name": "$name",
  "group": "$group",
  "key_name": "$key_name_generated",
  "environment": "$env_choice",
  "created_at": "$timestamp",
  "description": "$description"
}
EOJSON
  )

  # Validate JSON
  if ! echo "$json_data" | jq empty 2>/dev/null; then
    tum_error "Invalid JSON format"
    tum_pause
    return 1
  fi

  # Save metadata to JSON file
  local keychain_name=$(basename "$target_kc" .keychain-db)
  local metadata_dir="$HOME/.config/zsh/functions/keychain_manager/metadatas/$keychain_name"
  mkdir -p "$metadata_dir"
  local metadata_file="$metadata_dir/${key_name_generated}.json"
  echo "$json_data" | jq '.' >"$metadata_file"

  # Save the value to the keychain
  security add-generic-password \
    -a "$USER" \
    -s "$key_name_generated" \
    -w "$value" \
    "$target_kc"

  local result=$?
  if [[ $result -eq 0 ]]; then
    tum_success "Entry successfully saved to keychain"
    tum_info "Metadata file: $metadata_file"
  else
    tum_error "Failed to save entry to keychain"
  fi

  tum_pause
}
