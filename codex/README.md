# Codex

User-level configuration for the Codex CLI / desktop app.
[`install.sh`](../install.sh) creates three symlinks into `~/.codex/`:

| Symlink              | Target           |
| -------------------- | ---------------- |
| `~/.codex/AGENTS.md` | `codex/AGENTS.md` |
| `~/.codex/prompts`   | `codex/prompts/` |
| `~/.codex/skills`    | `codex/skills/`  |

## Intentionally untracked

- `config.toml` — the Codex app rewrites it with machine-specific absolute
  home paths (marketplace and runtime registrations), so it is git-ignored
  and stays local to each machine. Codex regenerates it on a fresh install.
- `skills/.system/` — app-managed bundled skills, git-ignored.
- Auth and state (`~/.codex/auth.json`, sqlite logs, transcripts) live in
  `~/.codex/` itself and never enter the repo.
