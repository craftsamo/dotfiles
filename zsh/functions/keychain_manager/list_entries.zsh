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
 
  # Define property categories
  local required_props=("created_at" "group" "name" "description")
  local optional_props=("value" "environment" "key_name" "${json_props[@]}")

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
    # Initialize default values
    local created_at="-" group="-" name="${service##*_}" environment="-" description="-"
    local dynamic_props=()

    if [[ -f "$metadata_file" ]]; then
      created_at=$(jq -r '.created_at // "-"' "$metadata_file")
      group=$(jq -r '.group // "-"' "$metadata_file")
      name=$(jq -r '.name // "-"' "$metadata_file")
      environment=$(jq -r '.environment // "-"' "$metadata_file")
      description=$(jq -r '.description // "-"' "$metadata_file")

      # Process any additional JSON properties that were selected
      for prop in "${json_props[@]}"; do
        if [[ " ${selected_props[*]} " == *" $prop "* ]]; then
          dynamic_props+=("$(jq -r ".$prop // \"-\"" "$metadata_file")")
        fi
      done
    fi

    # Build row based on selected properties
    local row=""
    local separator="|"

    for prop in "${selected_props[@]}"; do
      case "$prop" in
        created_at) row="${row}${created_at}${separator}" ;;
        group) row="${row}${group}${separator}" ;;
        name) row="${row}${name}${separator}" ;;
        environment) row="${row}${environment}${separator}" ;;
        value) row="${row}${value}${separator}" ;;
        description) row="${row}${description}${separator}" ;;
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
