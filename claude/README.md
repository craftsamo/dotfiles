# Claude Code

User-level configuration for Claude Code. [`install.sh`](../install.sh)
creates six symlinks into `~/.claude/`:

| Symlink                      | Target                    |
| ---------------------------- | ------------------------- |
| `~/.claude/CLAUDE.md`        | `claude/CLAUDE.md`        |
| `~/.claude/settings.json`    | `claude/settings.json`    |
| `~/.claude/keybindings.json` | `claude/keybindings.json` |
| `~/.claude/agents`           | `claude/agents/`          |
| `~/.claude/commands`         | `claude/commands/`        |
| `~/.claude/skills`           | `claude/skills/`          |

## User-managed content

- `CLAUDE.md` — global instructions, loaded into every session
- `settings.json` — permissions, hooks, model defaults
- `keybindings.json` — custom key bindings
- `agents/*.md` — personal subagents (markdown with YAML frontmatter)
- `commands/*.md` — personal slash commands (`/name`; `$ARGUMENTS` expands
  to the command arguments)
- `skills/<name>/SKILL.md` — personal skills

## Never tracked

State stays in `~/.claude/` itself: `history.jsonl`, `projects/`,
`sessions/`, `plugins/` (marketplace cache), backups and caches.
