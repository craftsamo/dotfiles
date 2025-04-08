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

  # Check if keychain is locked and unlock if necessary
  unlock_keychain "$target_name"

  # Find corresponding path
  local i=1
  for name in "${names[@]}"; do
    if [[ "$name" == "$target_name" ]]; then
      target_kc="${custom[$i]}"
      break
    fi
    ((i++))
  done

  # Select type
  local type
  type=$(tum_select "Select type" "Other" "GoogleCloud" "APIKey" "Web3Account")
  if [[ -z "$type" ]]; then
    type="Other"
  fi

  # Initialize common variables
  local name=""
  local value=""
  local description=""
  local group=""
  local key_name_generated=""

  # Input: group (optional, common for all types)
  group=$(tum_select "Select group" "NoGroup" "Other")
  if [[ -z "$group" || "$group" == "Other" ]]; then
    local input_group=""
    while true; do
      input_group=$(tum_input "Enter group name (required):")
      if [[ -n "$input_group" ]]; then
        group="$input_group"
        break
      else
        tum_error "Group name is required when selecting 'Other'"
      fi
    done
  fi

  # Select environment (common for all types)
  local env_choice
  env_choice=$(tum_select "Select environment" "Develop" "Production")
  if [[ -z "$env_choice" ]]; then
    env_choice="Develop"
  fi

  # Collect type-specific metadata based on selected type
  local additional_metadata="{}"

  case "$type" in
  "GoogleCloud")
    collect_googlecloud_metadata
    ;;
  "APIKey")
    collect_apikey_metadata
    ;;
  "Web3Account")
    collect_web3account_metadata
    ;;
  "Other")
    collect_other_metadata
    ;;
  esac

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

  # Input: description (optional, common for all types)
  description=$(tum_input "Enter description (optional):")

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Create JSON metadata by merging common and type-specific fields
  local common_data
  common_data=$(
    cat <<EOJSON
{
  "group": "$group",
  "type": "$type",
  "key_name": "$key_name_generated",
  "environment": "$env_choice",
  "created_at": "$timestamp",
  "description": "$description"
}
EOJSON
  )

  local json_data
  json_data=$(echo "$common_data" | jq --argjson add "$additional_metadata" '. + $add')

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

# Function for collecting metadata for "Other" type
function collect_other_metadata() {
  # Input: name (required)
  while true; do
    name=$(tum_input "Enter name (required):")
    if [[ -n "$name" ]]; then
      break
    else
      tum_error "Name is required"
    fi
  done

  # Generate key_name for "Other" type
  key_name_generated="${group}_${type}_${name}"

  # Update additional_metadata
  additional_metadata=$(
    cat <<EOF
{
  "name": "$name"
}
EOF
  )
}

# Function to collect GoogleCloud specific metadata
function collect_googlecloud_metadata() {
  # key_type is required for GoogleCloud
  key_type=$(tum_select "Select key type" "ProjectId" "ProjectNumber" "IdentityPoolId" "IdentityPoolProviderId")
  if [[ -z "$key_type" ]]; then
    key_type="ProjectId"
  fi

  # Generate key_name for GoogleCloud
  key_name_generated="${group}_${type}_${key_type}"

  # Update additional_metadata
  additional_metadata=$(
    cat <<EOF
{
  "key_type": "$key_type"
}
EOF
  )
}

# Function to collect APIKey specific metadata
function collect_apikey_metadata() {
  # service is required for APIKey
  local input_service=""
  while true; do
    input_service=$(tum_input "Enter service name (required):")
    if [[ -n "$input_service" ]]; then
      service="$input_service"
      break
    else
      tum_error "Service name is required"
    fi
  done

  # url is optional
  local url=""
  url=$(tum_input "Enter URL (optional):")

  # Generate key_name for APIKey
  key_name_generated="${group}_${type}_${service}"

  # Update additional_metadata
  additional_metadata=$(
    cat <<EOF
{
  "service": "$service",
  "url": "$url"
}
EOF
  )
}

# Function to collect Web3Account specific metadata
function collect_web3account_metadata() {
  # key_type is required for Web3Account
  key_type=$(tum_select "Select key type" "Mnemonic" "Private")
  if [[ -z "$key_type" ]]; then
    key_type="Mnemonic"
  fi

  # label is required
  local input_label=""
  while true; do
    input_label=$(tum_input "Enter label (required):")
    if [[ -n "$input_label" ]]; then
      break
    else
      tum_error "Label is required"
    fi
  done
  local label="$input_label"

  local index=""
  local address=""

  # For Private key type, index and address are required
  if [[ "$key_type" == "Private" ]]; then
    while true; do
      index=$(tum_input "Enter index (required for Private key):")
      if [[ -n "$index" ]]; then
        break
      else
        tum_error "Index is required for Private keys"
      fi
    done

    while true; do
      address=$(tum_input "Enter address (required for Private key):")
      if [[ -n "$address" ]]; then
        break
      else
        tum_error "Address is required for Private keys"
      fi
    done
  else
    # For Mnemonic, they are optional
    index=$(tum_input "Enter index (optional):")
    address=$(tum_input "Enter address (optional):")
  fi

  # Generate key_name for Web3Account
  key_name_generated="${group}_${type}_${key_type}_${label}"

  # Update additional_metadata
  additional_metadata=$(
    cat <<EOF
{
  "key_type": "$key_type",
  "label": "$label",
  "index": "$index",
  "address": "$address"
}
EOF
  )
}
