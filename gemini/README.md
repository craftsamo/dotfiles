# Gemini CLI

User-level configuration for Gemini CLI. [`install.sh`](../install.sh)
creates three symlinks into `~/.gemini/`:

| Symlink                   | Target                 |
| ------------------------- | ---------------------- |
| `~/.gemini/settings.json` | `gemini/settings.json` |
| `~/.gemini/GEMINI.md`     | `gemini/GEMINI.md`     |
| `~/.gemini/commands`      | `gemini/commands/`     |

## User-managed content

- `GEMINI.md` — global context, loaded into every session
- `settings.json` — CLI settings (auth type, theme, ...)
- `commands/**/*.toml` — custom slash commands; subdirectories namespace the
  command (`commands/git/commit.toml` -> `/git:commit`):

  ```toml
  description = "One-line description"
  prompt = "Do something with {{args}}"
  ```

## Never tracked

State stays in `~/.gemini/` itself: OAuth credentials, `user_id`, `tmp/` and
installed `extensions/`.
