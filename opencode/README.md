# opencode

XDG native: opencode reads `~/.config/opencode/` directly — no symlinks
needed.

## User-managed content

| Path             | Purpose                                                  |
| ---------------- | -------------------------------------------------------- |
| `opencode.jsonc` | main configuration (models, permissions, MCP, ...)       |
| `tui.json`       | TUI preferences                                          |
| `AGENTS.md`      | global instructions, loaded into every session           |
| `agent/`         | custom agents / subagents (`*.md`)                       |
| `command/`       | custom slash commands (`*.md`)                           |
| `instructions/`  | extra instruction files referenced from `opencode.jsonc` |
| `plugins/`       | plugins (`*.ts`)                                         |
| `skills/`        | skills (`<name>/SKILL.md`)                               |
| `tool/`          | custom tools (`*.ts`)                                    |

Empty directories carry a `.gitkeep` so the skeleton survives a fresh clone.

## Ignored machine state

`node_modules/`, `package.json`, `package-lock.json` and `bun.lock` are
created by opencode when plugins declare npm dependencies — see
[`.gitignore`](./.gitignore).
