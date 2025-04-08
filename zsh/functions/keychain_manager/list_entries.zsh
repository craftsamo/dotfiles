#!/usr/bin/env zsh

function list_entries() {
  tum_info "Keychain Entries"
  tum_separator

  # Get custom keychain paths and names
  local custom=($(get_keychains "path"))
  local names=($(get_keychains "name"))

  if [[ ${#custom[@]} -eq 0 ]]; then
    tum_error "No available custom keychains found."
    tum_pause
    return 1
  fi

  # Let user select a keychain by name
  local target_name
  local target_kc

  target_name=$(tum_select "Select keychain to view" "${names[@]}")
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

  # Collect all JSON properties from all metadata files
  local json_props=()
  local all_props_set=()
  local metadata_files=($metadata_dir/*.json)
 
  # Skip information.json and collect properties from all files
  for metadata_file in "${metadata_files[@]}"; do
    local basename_file=$(basename "$metadata_file")
    if [[ "$basename_file" != "information.json" && -f "$metadata_file" ]]; then
      local file_props=($(jq -r 'keys[]' "$metadata_file" 2>/dev/null))
      for prop in "${file_props[@]}"; do
        # Skip standard properties
        if [[ "$prop" != "created_at" && "$prop" != "group" && "$prop" != "name" && \
              "$prop" != "environment" && "$prop" != "description" && $prop != "key_name" && \
              ! " ${all_props_set[@]} " =~ " $prop " ]]; then
          json_props+=("$prop")
          all_props_set+=("$prop")
        fi
      done
    fi
  done
 
  # Define property categories based on entry type
  local required_props=("created_at" "group" "type")
  local optional_props=("value" "environment" "description")
  local type_specific_props=()
  
  # Get types from metadata for filtering
  local types=()
  local all_types_set=()
  for metadata_file in "${metadata_files[@]}"; do
    if [[ -f "$metadata_file" ]]; then
      local file_type=$(jq -r '.type // "Other"' "$metadata_file" 2>/dev/null)
      if [[ -n "$file_type" && ! " ${all_types_set[@]} " =~ " $file_type " ]]; then
        types+=("$file_type")
        all_types_set+=("$file_type")
      fi
    fi
  done

  # Let user filter by type if multiple types exist
  local selected_type=""
  if [[ ${#types[@]} -gt 1 ]]; then
    types=("All" "${types[@]}")
    selected_type=$(tum_select "Filter by entry type" "${types[@]}")
    if [[ -z "$selected_type" || "$selected_type" == "All" ]]; then
      selected_type=""
    fi
  fi

  # Add type-specific properties based on selected type
  if [[ -n "$selected_type" ]]; then
    case "$selected_type" in
      "GoogleCloud")
        required_props+=("key_type")
        ;;
      "APIKey")
        required_props+=("service" "url")
        ;;
      "Web3Account")
        required_props+=("key_type" "label")
        type_specific_props+=("index" "address")
        ;;
    esac
  else
    # If no type filter, add common type-specific properties
    type_specific_props+=("key_type" "service" "url" "label" "index" "address" "name")
  fi

  # Add JSON properties and type-specific properties to optional props
  optional_props+=("${json_props[@]}" "${type_specific_props[@]}")
 
  # Remove duplicates from optional properties and ensure required properties are not in optional list
  local filtered_optional_props=()
  local seen_props=()
 
  # First add required props to seen list
  for req_prop in "${required_props[@]}"; do
    seen_props+=("$req_prop")
  done
 
  # Then filter optional props
  for opt_prop in "${optional_props[@]}"; do
    if ! [[ " ${seen_props[*]} " == *" $opt_prop "* ]]; then
      filtered_optional_props+=("$opt_prop")
      seen_props+=("$opt_prop")
    fi
  done
 
  optional_props=("${filtered_optional_props[@]}")

  # Filter out required properties from optional properties to avoid duplicates
  local filtered_optional_props=()
  for opt_prop in "${optional_props[@]}"; do
    if ! [[ " ${required_props[*]} " == *" $opt_prop "* ]]; then
      filtered_optional_props+=("$opt_prop")
    fi
  done
  optional_props=("${filtered_optional_props[@]}")
  echo $optional_props

  # Let user select which optional properties to display
  local selected_optional_props=()
  if [[ ${#optional_props[@]} -gt 0 ]]; then
    selected_optional_props=($(tum_multiselect "Select additional columns to display" "${optional_props[@]}"))
  fi
 
  # Combine required and selected optional properties
  local selected_props=("${required_props[@]}" "${selected_optional_props[@]}")

  # Capitalize first letter of each property for headers
  local headers=()
  for prop in "${selected_props[@]}"; do
    headers+=("${(C)prop}")
  done
  local tmp_data=$(mktemp)

  # Process each service
  for service in "${services[@]}"; do
    # Get value from keychain
    local value=$(security find-generic-password -a "$USER" -s "$service" -w "$target_kc" 2>/dev/null)
    if [[ -z "$value" ]]; then
      continue
    fi

    # Check for metadata
    local metadata_file="$metadata_dir/${service}.json"
 
    # Skip if type filter is active and this entry doesn't match
    if [[ -n "$selected_type" && -f "$metadata_file" ]]; then
      local entry_type=$(jq -r '.type // "Other"' "$metadata_file")
      if [[ "$entry_type" != "$selected_type" ]]; then
        continue
      fi
    fi

    # Initialize default values for all possible properties
    local created_at="-" 
    local group="-" 
    local name="-" 
    local type="-"
    local environment="-" 
    local description="-"
    local key_type="-"
    local service_name="-"
    local url="-"
    local label="-"
    local index="-"
    local address="-"
    local dynamic_props=()

    if [[ -f "$metadata_file" ]]; then
      created_at=$(jq -r '.created_at // "-"' "$metadata_file")
      group=$(jq -r '.group // "-"' "$metadata_file")
      name=$(jq -r '.name // "-"' "$metadata_file")
      type=$(jq -r '.type // "-"' "$metadata_file")
      environment=$(jq -r '.environment // "-"' "$metadata_file")
      description=$(jq -r '.description // "-"' "$metadata_file")

      # Type-specific fields
      key_type=$(jq -r '.key_type // "-"' "$metadata_file")
      service_name=$(jq -r '.service // "-"' "$metadata_file")
      url=$(jq -r '.url // "-"' "$metadata_file")
      label=$(jq -r '.label // "-"' "$metadata_file")
      index=$(jq -r '.index // "-"' "$metadata_file")
      address=$(jq -r '.address // "-"' "$metadata_file")

      # Process any additional JSON properties that were selected
      for prop in "${json_props[@]}"; do
        if [[ " ${selected_props[*]} " == *" $prop "* ]]; then
          local dynamic_val=$(jq -r ".$prop // \"-\"" "$metadata_file")
          dynamic_props+=("$dynamic_val")
        fi
      done
    fi

    # Build row based on selected properties
    local row=""
    local separator="|"

    # Track which properties we've already processed to avoid duplicates
    local processed_props=()

    for prop in "${selected_props[@]}"; do
      # Skip if this property was already processed
      if [[ " ${processed_props[*]} " == *" $prop "* ]]; then
        continue
      fi

      processed_props+=("$prop")

      case "$prop" in
        created_at) row="${row}${created_at}${separator}" ;;
        group) row="${row}${group}${separator}" ;;
        name) row="${row}${name}${separator}" ;;
        type) row="${row}${type}${separator}" ;;
        environment) row="${row}${environment}${separator}" ;;
        value) row="${row}${value}${separator}" ;;
        description) row="${row}${description}${separator}" ;;
        key_type) row="${row}${key_type}${separator}" ;;
        service) row="${row}${service_name}${separator}" ;;
        url) row="${row}${url}${separator}" ;;
        label) row="${row}${label}${separator}" ;;
        index) row="${row}${index}${separator}" ;;
        address) row="${row}${address}${separator}" ;;
        *) 
          # Handle dynamic properties from JSON
          if [[ -f "$metadata_file" ]]; then
            local dynamic_val=$(jq -r ".$prop // \"-\"" "$metadata_file")
            row="${row}${dynamic_val}${separator}"
          else
            row="${row}-${separator}"
          fi
          ;;
      esac
    done

    # Remove trailing separator
    row="${row%|}"

    # Add row to data file
    echo "$row" >>"$tmp_data"
  done

  # Display the table using tum_table
  tum_table "${headers[@]}" <"$tmp_data"
  echo

  # Remove temporary file
  rm -f "$tmp_data"

  tum_pause
}
