# Function to change directory using fzf for selection
function _fzf_change_directory {
  fzf | perl -pe 's/([ ()])/\\\\$1/g' | read -r foo
  if [ "$foo" ]; then
    cd "$foo"
  fi
}

# Function to list directories and invoke _fzf_change_directory for selection
function fzf_change_directory {
  {
    # Add $HOME/.config to the list
    echo "$HOME/.config"
    # Find directories managed by ghq and exclude .git directories
    find "$(ghq root)" -maxdepth 4 -type d -name .git | sed 's/\/\.git//'
    # List directories in the current directory
    ls -d */ 2>/dev/null | perl -pe "s#^#$PWD/#"
    # List directories in $HOME/Github
    find "$HOME/Github" -maxdepth 1 -type d 2>/dev/null
  } | sed -e 's/\/$//' | awk '!a[$0]++' | _fzf_change_directory "$@"
}

zle -N fzf_change_directory
bindkey -M emacs '^F' fzf_change_directory