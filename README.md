# dotfiles

## Features

This configuration file contains.

- [Nvim](./nvim/README.md)
- [Zsh](./zsh/README.md)
- [Tmux](./tmux/README.md)

## Installation

1. [HomeBrew](https://brew.sh/en/)

```sh
mkdir ~/.homebrew
```

```sh
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C ~/.homebrew
```

2. Nvim dependencies

```sh
brew install neovim lazygit fzf nodebrew lynx gh tree-sitter git-flow, pngpaste
```

3. Tmux dependencies

```sh
brew install tmux lazygit readline
```

4. Zsh dependencies

```sh
brew install fzf ghq jq
```
