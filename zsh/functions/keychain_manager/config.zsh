source "${0:A:h}/create_keychain.zsh"
source "${0:A:h}/delete_keychain.zsh"
source "${0:A:h}/list_keychains.zsh"
source "${0:A:h}/add_entry.zsh"
source "${0:A:h}/get_entry.zsh"
source "${0:A:h}/update_entry.zsh"
source "${0:A:h}/list_entries.zsh"
source "${0:A:h}/export_entries.zsh"

function keychain_manager_main_menu() {
  tum_show_header "Keychain Manager"

  local choice
  choice=$(tum_select "Main Menu" "KeyChain" "Entry" "Exit")
  case "$choice" in
  "KeyChain") keychain_menu ;;
  "Entry") entry_menu ;;
  "Exit") return 0 ;;
  *)
    tum_error "Invalid selection"
    tum_pause
    keychain_manager_main_menu
    ;;
  esac
}

function keychain_menu() {
  tum_show_header "Keychain Operations"

  local choice
  choice=$(tum_select "KeyChain Operations" "Create" "Delete" "List" "Back")
  case "$choice" in
  "Create") create_keychain ;;
  "Delete")
    delete_keychain
    keychain_menu
    ;;
  "List")
    list_keychains
    tum_pause
    keychain_menu
    ;;
  "Back") keychain_manager_main_menu ;;
  *)
    tum_error "Invalid selection"
    tum_pause
    keychain_menu
    ;;
  esac
}

function entry_menu() {
  tum_show_header "Entry Operations"

  local choice
  choice=$(tum_select "Entry Operations" "Add Entry" "Get Entry" "Update Entry" "List Entries" "Export Entries" "Back")
  case "$choice" in
  "Add Entry") add_entry ;;
  "Get Entry") get_entry ;;
  "Update Entry") update_entry ;;
  "List Entries") list_entries ;;
  "Export Entries") export_entries ;;
  "Back") keychain_manager_main_menu ;;
  *)
    tum_error "Invalid selection"
    tum_pause
    entry_menu
    ;;
  esac
}
