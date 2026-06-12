# secret — macOS Keychain secrets CLI

`secret` manages development secrets (API keys, tokens, passwords) in the
macOS Keychain from the terminal: an fzf wizard, per-project organisation,
encrypted import/export, and one master password for every custom keychain.

Implementation: [`secret.zsh`](./secret.zsh) — plain zsh on top of the
built-in `/usr/bin/security`, no daemons. Loaded automatically by
[`config.zsh`](../config.zsh). `secret help` prints the full reference.

## Requirements

From the [Brewfile](../../Brewfile): `fzf` (interactive UI), `jq`
(JSON import/export), `age` (encrypted exports).

## Quick start

```sh
secret                          # fzf wizard: Get / Add / Update / List / Show / Delete / Export / Import
secret set STRIPE_KEY -j "prod key, rotate in dashboard" -D "api key"
secret get STRIPE_KEY           # value on stdout   (-c: clipboard, auto-clears in 45 s)
secret ls --long                # names + kind + modified + comment
eval "$(secret env -p global)"  # inject a whole project as environment variables
```

Inside a git repository the project defaults to the repository name;
otherwise to `global`. `-p NAME` overrides.

## Data model

One keychain item per secret — fully visible and editable in Keychain Access:

| Attribute | Value                                                                       |
| --------- | --------------------------------------------------------------------------- |
| service   | `secret.<project>` — namespace marker, lookup key together with account     |
| account   | the variable name (`TAVILY_API_KEY`) — **unique key, do not repurpose**     |
| label     | `NAME` inside the project's own keychain, `<project>/NAME` in shared ones   |
| kind      | free text shown in the GUI, default `ENV` (`-D`)                            |
| comment   | free-form description (`-j`), shown by `show` / `ls --long` / the GUI       |

## Keychains

Resolution order, per item:

1. `-k NAME|PATH` explicit override (`-k default` forces the login keychain)
2. `~/Library/Keychains/<project>.keychain-db` — per-project keychain
3. `~/Library/Keychains/global.keychain-db` — the base for everything else
4. the login keychain (only when no `global` keychain exists)

Steps 2–3 only apply to keychains **registered in the user search list**, so
a project name colliding with an app/system keychain file (`metadata`,
`parallels_shared`, ...) never writes there. `secret keychain create` and
`secret keychain register` handle registration.

### Master password

All custom keychains share one password, kept in a password manager. A copy
lives in the login keychain so everything unlocks silently:

```
macOS login password
  └─ login.keychain-db ── keychain-password/master (one item)
       ├─ global.keychain-db        (all secrets without their own keychain)
       └─ <project>.keychain-db ... (created instantly, no prompt)
```

| Command                              | Purpose                                                      |
| ------------------------------------ | ------------------------------------------------------------ |
| `secret keychain master set`         | define it and rotate every registered custom keychain to it  |
| `secret keychain master rotate`      | change it everywhere at once                                 |
| `secret keychain master status`      | unlock source (`master`/`individual`/`none`) + lock state    |
| `secret keychain master reveal [-c]` | show / copy it (for the password manager)                    |
| `secret keychain master forget`      | remove the login copy (access starts prompting)              |
| `secret keychain create NAME`        | new keychain — no password prompt once a master is set       |
| `secret keychain register NAME`      | add a copied `.keychain-db` to the search list               |
| `secret keychain remember NAME`      | per-keychain password override (takes precedence)            |
| `secret keychain ls` | inventory and lifecycle                                  |
| `secret keychain info` | inventory and lifecycle                                  |
| `secret keychain lock` | inventory and lifecycle                                  |
| `secret keychain unlock` | inventory and lifecycle                                  |
| `secret keychain rm` | inventory and lifecycle                                  |

## Import / export

| Format          | Metadata | Protection                                  |
| --------------- | -------- | ------------------------------------------- |
| `age` (default) | kept     | age passphrase encryption (`.json.age`)     |
| `json`          | kept     | plaintext JSON, `chmod 600`                 |
| `env`           | lost     | plaintext `export NAME='...'`, `chmod 600`  |

```sh
secret export -p global                  # -> secret-export-global-YYYYMMDD.json.age
secret export --all --format env -o dev.env
secret import dev.env -p myproj          # format auto-detected; JSON items keep
secret import backup.json.age            # their own project unless -p is given
```

Keychain unlock passwords are **never** part of an export. Encrypted exports
are the recommended off-machine backup: they restore without the keychain
files or the master password.

### New machine / recovery

```sh
~/.config/install.sh --deps              # fzf, jq, age

# Option A — keychain file copied over from the old machine:
secret keychain register global
secret keychain master set               # master password from the password manager

# Option B — from an encrypted export:
secret keychain create global --no-autolock
secret import secret-export-global-YYYYMMDD.json.age
```

## Security model

- Secret values never appear in process argv: writes are piped to
  `security -i` on stdin, interactive entry uses zsh `read -s`, reads use
  `find-generic-password -w`.
- Values are single-line; control characters are rejected.
- fzf — including preview — only ever sees names and metadata.
- Clipboard copies clear after 45 s unless something else was copied since.
- Known limitation: items created by `secret` are readable via
  `/usr/bin/security` without a GUI prompt **while their keychain is
  unlocked**. That is what makes a CLI workflow possible, and it means
  malware running as the logged-in user is outside the threat model (true
  for every keychain CLI). At-rest protection comes from the keychain
  encryption (master password) plus FileVault.

## Tests

[`zsh/tests/secret-selftest.zsh`](../tests/secret-selftest.zsh) — 100
assertions: round-trips (special characters, json/env/age), partial updates,
keychain auto-mapping, master adoption/rotation, auto-unlock. It only uses
throwaway `secret-selftest*` projects/keychains, isolates the master tests
via the `SECRET_MASTER_ACCOUNT` / `SECRET_TEST_ONLY_KC` hooks, and cleans up
after itself — safe to run on a machine with real data.

```sh
zsh -f ~/.config/zsh/tests/secret-selftest.zsh
```
