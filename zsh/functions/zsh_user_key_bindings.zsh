source ~/.config/zsh/functions/utils/utils_manager.zsh
source ~/.config/zsh/functions/fzf_change_directory.zsh
source ~/.config/zsh/functions/keychain_manager.zsh

# peco
zle -N fzf_change_directory
bindkey -M emacs '^F' fzf_change_directory

# vim-like
# bindkey -M emacs '^l' forward-char

# prevent iTerm2 from closing when typing Ctrl-D (EOF)
bindkey -M emacs '^D' delete-char

# keychain manager
function keychain_manager_widget() {
  zle -I
  keychain_manager_main_menu
  zle reset-prompt
}
zle -N keychain_manager_widget
bindkey -M emacs '^K' keychain_manager_widget
