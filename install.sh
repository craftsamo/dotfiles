#!/usr/bin/env bash
#
# Recreate symlinks from tool config dirs (~/.claude, ~/.codex) into this repo.
# Idempotent: safe to run repeatedly. Also serves as a drift detector — if a
# tool replaced a symlink with a regular file, this script warns and skips it
# instead of overwriting.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0

link() {
  local target="$1" dest="$2"
  if [ ! -e "$target" ]; then
    echo "SKIP: missing target: $target"
    status=1
    return
  fi
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "WARN: $dest exists and is not a symlink — not overwriting (drift?)"
    status=1
    return
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$target" "$dest"
  echo "  ok: $dest -> $target"
}

echo "[claude]"
link "$DOTFILES/claude/CLAUDE.md"        "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/settings.json"    "$HOME/.claude/settings.json"
link "$DOTFILES/claude/keybindings.json" "$HOME/.claude/keybindings.json"
link "$DOTFILES/claude/skills"           "$HOME/.claude/skills"
link "$DOTFILES/claude/agents"           "$HOME/.claude/agents"
link "$DOTFILES/claude/commands"         "$HOME/.claude/commands"

echo "[codex]"
link "$DOTFILES/codex/AGENTS.md"   "$HOME/.codex/AGENTS.md"
link "$DOTFILES/codex/config.toml" "$HOME/.codex/config.toml"
link "$DOTFILES/codex/prompts"     "$HOME/.codex/prompts"
link "$DOTFILES/codex/skills"      "$HOME/.codex/skills"

exit $status
