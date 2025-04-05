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
  choice=$(tum_select "KeyChain Operations" "Create" "Delete" "Back")
  case "$choice" in
  "Create") create_keychain ;;
  "Delete")
    delete_keychain
    keychain_menu
    ;;
  esac
}
