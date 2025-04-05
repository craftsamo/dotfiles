#!/usr/bin/env zsh

# Show a checklist of items with their completion status
function tum_checklist() {
  local title="$1"
  shift

  echo "$title:"

  local item result indicator
  for item in "$@"; do
    # Split the item on : to get status
    result=${item##*:}
    item=${item%:*}

    case "$result" in
    "done") indicator="✅" ;;
    "pending") indicator="⏳" ;;
    "failed") indicator="❌" ;;
    *) indicator="⬜" ;;
    esac

    printf "  %s %s\n" "$indicator" "$item"
  done
  echo
}
