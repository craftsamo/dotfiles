setopt interactivecomments

export TERM=screen-256color

# Theme settings
# set -g theme_color_scheme terminal-dark
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# Aliases
alias ls="ls -p --color=auto"
alias la="ls -A"
alias ll="ls -l"
alias lla="ll -A"
alias g="git"

# NVM
command -v nvim >/dev/null && alias vim=nvim

export EDITOR=nvim

function __check_nvm() {
  if [ -f .nvmrc ] && [ -r .nvmrc ]; then
    nvm use
  fi
}
# add-zsh-hook chpwd __check_nvm

# Homebrew
export HOMEBREW_PREFIX="$HOME/.homebrew"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"

# Nodebrew
export PATH=$HOME/.nodebrew/current/bin:$HOME/.homebrew/bin:$HOME/.local/bin:$HOME/bin:/bin:/usr/bin:/usr/local/bin:$PATH
export PATH=$HOME/.nodebrew/current/bin:$PATH

# Docker
export PATH=$HOME/.docker/bin:$PATH

setopt magic_equal_subst

# Load all .zsh files from a specified directory
load_files_in_directory() {
  local directory="$1"
  local extension="$2"

  if [ -d "$directory" ]; then
    for file in "$directory"/*.$extension; do
      if [ -f "$file" ] && [ "$file" != "$HOME/.config/zsh/config.zsh" ]; then
        source "$file"
      fi
    done
  fi
}

load_files_in_directory "$HOME/.config/zsh/conf.d" "zsh"
load_files_in_directory "$HOME/.config/zsh/functions" "zsh"
load_files_in_directory "$HOME/.config/zsh" "zsh"
