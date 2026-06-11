source ~/.config/zsh/functions/fzf_change_directory.zsh

# peco
zle -N fzf_change_directory
bindkey -M emacs '^F' fzf_change_directory

# vim-like
# bindkey -M emacs '^l' forward-char

# prevent iTerm2 from closing when typing Ctrl-D (EOF)
bindkey -M emacs '^D' delete-char
