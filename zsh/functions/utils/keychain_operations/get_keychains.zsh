#!/usr/bin/env zsh

function get_keychains() {
  local mode="${1:-path}"
  local all
  all=($(security list-keychains -d user | tr -d '"' | sed 's/^[ \t]*//;s/[ \t]*$//'))
  local paths=()
  local names=()
  local display=()

  for kc in "${all[@]}"; do
    if [[ "$kc" != *"login.keychain"* ]] && [[ "$kc" != *"LocalItems.keychain"* ]]; then
      local name=$(basename "$kc" | sed 's/\.keychain.*$//')
      paths+=("$kc")
      names+=("$name")
      display+=("$name ($kc)")
    fi
  done

  case "$mode" in
  path) printf "%s\n" "${paths[@]}" ;;
  name) printf "%s\n" "${names[@]}" ;;
  display) printf "%s\n" "${display[@]}" ;;
  all)
    local i=1
    while [ $i -le ${#names[@]} ]; do
      local name="${names[$i]}"
      local path="${paths[$i]}"
      printf "%s:%s\n" "$name" "$path"
      ((i++))
    done
    ;;
  esac
}
