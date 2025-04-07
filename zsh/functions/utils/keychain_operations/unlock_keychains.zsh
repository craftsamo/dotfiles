#!/usr/bin/env zsh

function unlock_keychain() {
  local keychain_name="$1"
  local keychain_path="$HOME/Library/Keychains/${keychain_name}.keychain-db"

  # Check if keychain exists
  if [[ ! -f "$keychain_path" ]]; then
    tum_error "Keychain '$keychain_name' not found"
    return 1
  fi

  # Check for password existence in metadata JSON file
  local metadata_file="$HOME/.config/zsh/functions/keychain_manager/metadatas/${keychain_name}/information.json"
  local has_password=false

  if [[ -f "$metadata_file" ]]; then
    has_password=$(jq -r '.has_password // false' "$metadata_file")
  fi

  # Bypass if there is no password
  if [[ "$has_password" == false ]]; then
    # No need to unlock keychain created without password
    tum_info "Keychain '$keychain_name' was created without a password"
    return 0
  fi

  # Use expect to retrieve password from login keychain
  local stored_password
  stored_password=$(security find-generic-password -a "$USER" -s "CustomKeychainPassword_${keychain_name}" -w login.keychain)
  local password_status=$?

  if [[ $password_status -ne 0 || -z "$stored_password" ]]; then
    # If password is not stored, ask user for input
    tum_warn "Keychain '$keychain_name' is protected but no saved password was found"
    local password=$(tum_masked_input "Enter password for keychain '$keychain_name':")
    if [[ -z "$password" ]]; then
      tum_error "No password was provided"
      return 1
    fi
    stored_password="$password"
  fi

  # Unlock the keychain
  security unlock-keychain -p "$stored_password" "$keychain_path" 2>/dev/null
  local unlock_status=$?

  if [[ $unlock_status -eq 0 ]]; then
    return 0
  else
    tum_error "Failed to unlock keychain '$keychain_name'"
    return 1
  fi
}

function unlock_keychains() {
  # Unlock all custom keychains
  local names=($(get_keychains "name"))
  local paths=($(get_keychains "path"))

  if [[ ${#names[@]} -eq 0 ]]; then
    tum_warn "No custom keychains found to unlock"
    return 0
  fi

  local success_count=0
  local failure_count=0

  for name in "${names[@]}"; do
    unlock_keychain "$name"
    if [[ $? -eq 0 ]]; then
      ((success_count++))
    else
      ((failure_count++))
    fi
  done

  tum_info "Unlocked $success_count keychains. $failure_count failures."
  return 0
}
