#!/usr/bin/env zsh

function delete_keychain() {
  tum_info "Delete Custom Keychain"
  tum_separator
  echo

  # Get name and path information from `get_keychains`
  local names=($(get_keychains "name"))
  local paths=($(get_keychains "path"))

  if [[ ${#names[@]} -eq 0 ]]; then
    tum_error "No custom keychains found."
    tum_pause
    return 1
  fi

  # Allow users to choose
  local selected
  selected=$(tum_select "Select keychain to delete" "${names[@]}")
  if [[ -z "$selected" ]]; then
    tum_warn "No keychain selected."
    tum_pause
    return 0
  fi

  # Get path from selected name
  local target=""
  local i=1
  for name in "${names[@]}"; do
    if [[ "$name" == "$selected" ]]; then
      target="${paths[$i]}"
      break
    fi
    ((i++))
  done

  # Extract keychain name (for password retrieval)
  local keychain_name=$(basename "$target" .keychain-db)

  # Check if there's a stored password for this keychain
  local stored_password
  stored_password=$(security find-generic-password -a "$USER" -s "CustomKeychainPassword_${keychain_name}" -w login.keychain 2>/dev/null)
  local password_status=$?

  # Unlock keychain (if locked)
  unlock_keychain "$keychain_name"

  # confirmation message
  echo
  if ! tum_confirm "Are you sure you want to delete keychain '$selected'?"; then
    tum_warn "Operation cancelled."
    tum_pause
    return 0
  fi

  tum_separator

  # Delete the keychain itself
  security delete-keychain "$target"
  local keychain_status=$?

  # Extract keychain name (get file name without extension from path)
  local keychain_name=$(basename "$target" .keychain-db)

  # Create paths to relevant metadata directories
  local metadata_dir="$HOME/.config/zsh/functions/keychain_manager/metadatas/$keychain_name"

  # Remove the associated password from the login keychain (if it exists)
  security delete-generic-password -a "$USER" -s "CustomKeychainPassword_${keychain_name}" login.keychain &>/dev/null
  local password_status=$?

  # Delete metadata directory (if present)
  if [[ -d "$metadata_dir" ]]; then
    rm -rf "$metadata_dir"
    local metadata_status=$?
  else
    local metadata_status=0
  fi

  echo
  if [[ $keychain_status -eq 0 ]]; then
    tum_success "🔑 Keychain: '$selected' has been removed."
  else
    tum_error "🔑 Keychain: Failed to remove '$selected'."
  fi

  if [[ $password_status -eq 0 ]]; then
    tum_success "🔒 Password: Removed for keychain '$selected'."
  else
    tum_warn "🔒 Password: No password found or removal failed."
  fi

  if [[ $metadata_status -eq 0 ]]; then
    tum_success "📁 Metadata: Removed for keychain '$selected'."
  else
    tum_error "📁 Metadata: Failed to remove directory."
  fi

  tum_pause
}
