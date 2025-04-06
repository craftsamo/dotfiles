#!/usr/bin/env zsh

function create_keychain() {
  tum_info "Create New Custom Keychain"
  tum_separator
  echo

  local ck_name=$(tum_input "Enter keychain name (e.g. MyCustomKeychain):")
  if [[ -z "$ck_name" ]]; then
    tum_error "Keychain name is required"
    tum_pause
    return 1
  fi

  local ck_path="$HOME/Library/Keychains/${ck_name}.keychain-db"
  if [[ -f "$ck_path" ]]; then
    tum_error "$ck_path already exists."
    tum_pause
    return 1
  fi

  echo
  local ck_password=$(tum_masked_input "Enter keychain password (optional, leave empty for none):")

  # Create the keychain
  security create-keychain -p "$ck_password" "$ck_path"
  if [[ $? -ne 0 ]]; then
    tum_error "Failed to create keychain"
    tum_pause
    return 1
  fi
  security set-keychain-settings -lut 7200 "$ck_path"

  # Store password in login keychain if password was provided
  if [[ -n "$ck_password" ]]; then
    security add-generic-password -a "$USER" \
      -s "CustomKeychainPassword_${ck_name}" \
      -w "$ck_password" \
      -D "Custom Keychain Password" \
      -j "Password for custom keychain: ${ck_name}" \
      -T "" \
      login.keychain
  fi

  # Get existing keychain list
  local existing_keychains
  existing_keychains=($(security list-keychains -d user | tr -d '"' | xargs))

  # Add new keychain and reconfigure
  security list-keychains -d user -s "$ck_path" "${existing_keychains[@]}"

  # Unlock keychain (if needed)
  security unlock-keychain -p "$ck_password" "$ck_path"

  # Store keychain metadata in JSON format
  local metadata_dir="$HOME/.config/zsh/functions/keychain_manager/metadatas/${ck_name}"
  local metadata_file="$metadata_dir/information.json"

  # Create directory if it doesn't exist
  mkdir -p "$metadata_dir"

  # Get current date and time
  local created_at=$(date "+%Y-%m-%d %H:%M:%S")

  # Get keychain settings
  local keychain_settings=$(security show-keychain-info "$ck_path" 2>&1)
  local lock_timeout=$(echo "$keychain_settings" | grep -o "timeout=[0-9]*" | cut -d= -f2)

  # Create JSON with keychain information
  cat >"$metadata_file" <<EOF
{
  "created_at": "$created_at",
  "name": "$ck_name",
  "path": "$ck_path",
  "lock_timeout": "$lock_timeout",
  "owner": "$USER",
  "has_password": $([ -n "$ck_password" ] && echo "true" || echo "false"),
  "password_keychain_entry": $([ -n "$ck_password" ] && echo "\"CustomKeychainPassword_${ck_name}\"" || echo "null")
}
EOF

  chmod 600 "$metadata_file"

  # Display success message
  tum_success "Custom keychain created and added to keychain list: $ck_path"

  tum_pause
}
