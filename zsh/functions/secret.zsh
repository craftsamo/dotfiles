# secret.zsh — manage secrets in the macOS Keychain (CLI + fzf wizard)
#
#   secret                       interactive wizard (fzf)
#   secret set NAME [-p proj] [-j comment] [-D kind] [--stdin]
#   secret update NAME [-p proj] [-j comment] [-D kind] [--value|--stdin]
#   secret get NAME [-p proj] [-c|--copy]
#   secret show NAME [-p proj]
#   secret ls [-p proj] [-l|--long]
#   secret projects
#   secret env [-p proj]
#   secret rm NAME [-p proj] [-f|--force]
#   secret export [-p proj|--all] [-o FILE] [--format age|json|env]
#   secret import FILE [-p proj] [-y|--yes]
#   secret keychain create|ls|info|lock|unlock|rm ...
#   secret help
#
# Data model — native keychain attributes (fully visible in Keychain Access):
#   service = secret.<project>      account = NAME (the unique lookup key)
#   label   = NAME inside the project's own keychain, else <project>/NAME
#   kind    = -D (default "ENV")    comment = -j (free-form description)
# Project resolution: -p flag > basename of `git rev-parse --show-toplevel` > "global".
# Keychain resolution (per item, by project):
#   1. -k NAME|PATH  explicit override ("-k default" = the system default keychain)
#   2. ~/Library/Keychains/<project>.keychain-db  (per-project auto-mapping)
#   3. ~/Library/Keychains/global.keychain-db     (preferred base — create it
#      with `secret keychain create global` to keep secrets out of login)
#   4. the system default keychain (login)
# Steps 2-3 only apply to keychains registered in the user search list.
#
# Security invariants:
#   - secret values never appear in process argv: writes are piped to
#     `security -i` on stdin, interactive entry uses zsh `read -s`
#   - values are single-line; control characters are rejected
#   - fzf only ever sees names and metadata, never values
#   - clipboard copies are cleared after 45s (unless overwritten meanwhile)
#
# Test hooks: SECRET_AGE_ARGS / SECRET_AGE_DECRYPT_ARGS override the age
# flags used by export/import (default: -p, i.e. passphrase mode).
# SECRET_MASTER_ACCOUNT overrides the login account of the master password
# item; SECRET_TEST_ONLY_KC (glob) limits which custom keychains the
# master set/rotate loops touch. Both exist for the self-tests.

# ---------------------------------------------------------------- helpers --

_secret_err() { print -r -- "secret: $*" >&2; }

_secret_default_keychain() {
  security default-keychain 2>/dev/null \
    | sed -E 's/^[[:space:]]*"(.*)"[[:space:]]*$/\1/'
}

_secret_resolve_keychain() {   # $1: -k value (may be empty) -> path/name on stdout
  local k=$1
  if [[ -z $k || $k == default ]]; then _secret_default_keychain; return; fi
  if [[ -e $k ]]; then print -r -- "$k"
  elif [[ -e $HOME/Library/Keychains/$k ]]; then print -r -- "$HOME/Library/Keychains/$k"
  elif [[ -e $HOME/Library/Keychains/$k.keychain-db ]]; then print -r -- "$HOME/Library/Keychains/$k.keychain-db"
  else print -r -- "$k"        # let security resolve it by name
  fi
}

# Keychain for a project: explicit -k > <project>.keychain-db > default.
# Auto-mapping only applies to keychains in the user search list, so a
# project name colliding with an app/system keychain file (metadata,
# parallels_shared, ...) never writes there by accident.
# Relies on $_kc, $_kc_default, $_kc_explicit, $_kc_sl set by the dispatcher.
_secret_kc_for() {             # $1 project -> keychain path/name on stdout
  local mapped=$HOME/Library/Keychains/$1.keychain-db
  if (( _kc_explicit )); then
    print -r -- "$_kc"
  elif [[ -e $mapped ]] && (( ${_kc_sl[(Ie)$mapped]} )); then
    print -r -- "$mapped"
  else
    print -r -- "$_kc"
  fi
}

_secret_kc_label() {           # $1 project -> keychain name when auto-mapped away
  (( _kc_explicit )) && return 0           # explicit -k: target is obvious
  local kc
  kc=$(_secret_kc_for "$1")
  [[ $kc == "$_kc" ]] && return 0          # the implicit base: obvious too
  print -r -- "${${kc:t}%.keychain-db}"
}

_secret_kc_suffix() {          # $1 project -> " [kc:NAME]" for UI headers, or ""
  local l
  l=$(_secret_kc_label "$1")
  [[ -n $l ]] && print -rn -- " [kc:$l]"
  return 0
}

# Auto-unlock: the login keychain may hold unlock passwords as items with
# service "keychain-password":
#   account "<keychain name>"  per-keychain (secret keychain remember)
#   account "master"           shared master (secret keychain master set)
# Lookup order: per-keychain item > master item > give up (GUI prompt).
# No-op for the default keychain or when nothing is stored.
_secret_master_account() { print -r -- "${SECRET_MASTER_ACCOUNT:-master}"; }

_secret_kc_ensure() {          # $1 keychain path/name
  local kc=$1
  [[ -z $kc || $kc == "$_kc_default" ]] && return 0
  local pw
  pw=$(security find-generic-password -s 'keychain-password' \
        -a "${${kc:t}%.keychain-db}" -w "$_kc_default" 2>/dev/null)
  if [[ -z $pw ]]; then
    pw=$(security find-generic-password -s 'keychain-password' \
          -a "$(_secret_master_account)" -w "$_kc_default" 2>/dev/null)
  fi
  [[ -n $pw ]] || return 0
  print -r -- "unlock-keychain -p $(_secret_quote_si "$pw") $(_secret_quote_si "$kc")" \
    | security -i >/dev/null 2>&1
  return 0
}

_secret_resolve_project() {    # $1: -p value (may be empty)
  local p=$1 top
  if [[ -n $p ]]; then print -r -- "$p"; return; fi
  if top=$(command git rev-parse --show-toplevel 2>/dev/null) && [[ -n $top ]]; then
    print -r -- "${top:t}"; return
  fi
  print -r -- global
}

_secret_check_name() {
  [[ $1 =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]] && return 0
  _secret_err "invalid name '$1' (letters, digits, underscores; must not start with a digit)"
  return 1
}

_secret_check_project() {
  [[ -n $1 && $1 != *[/$'\t'$'\n']* ]] && return 0
  _secret_err "invalid project name '$1' (must be non-empty, no '/', tabs or newlines)"
  return 1
}

_secret_fmt_date() {           # 20250612053000Z -> 2025-06-12 05:30
  local d=$1
  if [[ ${#d} -ge 12 && $d == [0-9]* ]]; then
    print -r -- "${d[1,4]}-${d[5,6]}-${d[7,8]} ${d[9,10]}:${d[11,12]}"
  else
    print -r -- "$d"
  fi
}

_secret_quote_si() {           # quote one argument for the `security -i` parser
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  print -r -- "\"$s\""
}

_secret_prompt_value() {       # $1 display label; hidden double prompt, value on stdout
  local v1 v2
  IFS= read -rs "v1?value for $1 (hidden): " || { print '' >&2; return 1 }
  print '' >&2
  IFS= read -rs "v2?retype to confirm: " || { print '' >&2; return 1 }
  print '' >&2
  [[ "$v1" == "$v2" ]] || { _secret_err "values do not match, aborted"; return 1 }
  print -r -- "$v1"
}

_secret_store() {              # $1 name  $2 project  $3 comment  $4 kind ; value on stdin
  local name=$1 proj=$2 comment=$3 kind=$4 value extra err
  IFS= read -r value
  if IFS= read -r extra; then
    _secret_err "$proj/$name: multi-line values are not supported"; return 1
  fi
  if [[ -z $value ]]; then
    _secret_err "$proj/$name: empty value, skipped"; return 1
  fi
  if [[ $value == *[[:cntrl:]]* ]]; then
    _secret_err "$proj/$name: control characters are not supported"; return 1
  fi
  local kc
  kc=$(_secret_kc_for "$proj")
  _secret_kc_ensure "$kc"
  # label: just NAME inside the project's own keychain (context is clear);
  # "<project>/NAME" in shared keychains (login / the global base)
  local label=$name
  [[ ${${kc:t}%.keychain-db} == "$proj" ]] || label="$proj/$name"
  local cmd="add-generic-password -U"
  cmd+=" -a $(_secret_quote_si "$name")"
  cmd+=" -s $(_secret_quote_si "secret.$proj")"
  cmd+=" -l $(_secret_quote_si "$label")"
  cmd+=" -D $(_secret_quote_si "${kind:-ENV}")"
  cmd+=" -j $(_secret_quote_si "$comment")"
  cmd+=" -w $(_secret_quote_si "$value")"
  cmd+=" $(_secret_quote_si "$kc")"
  err=$(print -r -- "$cmd" | security -i 2>&1 >/dev/null)
  if ! security find-generic-password -s "secret.$proj" -a "$name" "$kc" >/dev/null 2>&1; then
    _secret_err "failed to store $proj/$name${err:+ — ${err//$'\n'/ }}"
    return 1
  fi
}

_secret_get_value() {          # $1 name  $2 project -> value on stdout
  local kc
  kc=$(_secret_kc_for "$2")
  _secret_kc_ensure "$kc"
  security find-generic-password -s "secret.$2" -a "$1" -w "$kc" 2>/dev/null
}

_secret_exists() {             # $1 name  $2 project (attribute lookup only)
  local kc
  kc=$(_secret_kc_for "$2")
  _secret_kc_ensure "$kc"
  security find-generic-password -s "secret.$2" -a "$1" "$kc" >/dev/null 2>&1
}

_secret_delete() {             # $1 name  $2 project
  local kc
  kc=$(_secret_kc_for "$2")
  _secret_kc_ensure "$kc"
  security delete-generic-password -s "secret.$2" -a "$1" "$kc" >/dev/null 2>&1
}

# All secret.* items in one keychain ($1, defaults to the base keychain).
# TSV rows: project \t name \t label \t kind \t comment \t mdate
_secret_dump_items() {
  local kc=${1:-$_kc}
  _secret_kc_ensure "$kc"
  security dump-keychain "$kc" 2>/dev/null | awk '
    function val(s) {
      sub(/^[^=]*=/, "", s)
      if (s == "<NULL>") return ""
      gsub(/^"|"$/, "", s)
      return s
    }
    function flush() {
      if (item && svce ~ /^secret\./)
        printf "%s\t%s\t%s\t%s\t%s\t%s\n", substr(svce, 8), acct, labl, desc, icmt, mdat
      item = 0
    }
    /^keychain:/            { flush() }
    /^class: "genp"/        { item = 1; acct = svce = labl = desc = icmt = mdat = ""; next }
    !item                   { next }
    /^ *"acct"<blob>=/      { acct = val($0) }
    /^ *"svce"<blob>=/      { svce = val($0) }
    /^ *0x00000007 <blob>=/ { labl = val($0) }
    /^ *"desc"<blob>=/      { desc = val($0) }
    /^ *"icmt"<blob>=/      { icmt = val($0) }
    /^ *"mdat"<timedate>=/  {
      if (match($0, /"[0-9]+Z\\000"/)) mdat = substr($0, RSTART + 1, RLENGTH - 6)
    }
    END { flush() }
  '
}

_secret_rows() {               # $1 project ("" = all projects in the base keychain)
  if [[ -n $1 ]]; then
    _secret_dump_items "$(_secret_kc_for "$1")" | awk -F'\t' -v p="$1" '$1 == p'
  else
    _secret_dump_items
  fi | sort -t$'\t' -k1,1 -k2,2
}

_secret_clip() {               # copy $1, auto-clear after 45s if still ours
  print -rn -- "$1" | pbcopy
  ( sleep 45
    [[ "$(pbpaste 2>/dev/null)" == "$1" ]] && pbcopy </dev/null
  ) >/dev/null 2>&1 &!
}

_secret_tsv_unescape() {       # undo jq @tsv escaping
  local s=$1
  s=${s//'\\'/$'\x01'}
  s=${s//'\t'/$'\t'}
  s=${s//'\n'/$'\n'}
  s=${s//'\r'/$'\r'}
  s=${s//$'\x01'/\\}
  print -r -- "$s"
}

# ------------------------------------------------------------ subcommands --

_secret_cmd_set() {
  local name="" proj="" comment="" kind="" from_stdin=0
  while (( $# )); do
    case $1 in
      -p) proj=$2; shift 2 ;;
      -j) comment=$2; shift 2 ;;
      -D) kind=$2; shift 2 ;;
      --stdin) from_stdin=1; shift ;;
      -*) _secret_err "set: unknown option '$1'"; return 2 ;;
      *) name=$1; shift ;;
    esac
  done
  [[ -z $name ]] && { _secret_err "set: NAME required"; return 2 }
  _secret_check_name "$name" || return 2
  proj=$(_secret_resolve_project "$proj")
  _secret_check_project "$proj" || return 2

  if (( from_stdin )) || [[ ! -t 0 ]]; then
    _secret_store "$name" "$proj" "$comment" "$kind" || return 1
  else
    local value
    value=$(_secret_prompt_value "$proj/$name") || return 1
    print -r -- "$value" | _secret_store "$name" "$proj" "$comment" "$kind" || return 1
  fi
  local lbl
  lbl=$(_secret_kc_label "$proj")
  print -r -- "stored $proj/$name${lbl:+ [keychain: $lbl]}"
}

_secret_cmd_update() {
  local name="" proj="" comment="" kind=""
  local comment_set=0 kind_set=0 want_value=0 from_stdin=0
  while (( $# )); do
    case $1 in
      -p) proj=$2; shift 2 ;;
      -j) comment=$2; comment_set=1; shift 2 ;;
      -D) kind=$2; kind_set=1; shift 2 ;;
      --value) want_value=1; shift ;;
      --stdin) from_stdin=1; shift ;;
      -*) _secret_err "update: unknown option '$1'"; return 2 ;;
      *) name=$1; shift ;;
    esac
  done
  [[ -z $name ]] && { _secret_err "update: NAME required"; return 2 }
  proj=$(_secret_resolve_project "$proj")
  if ! _secret_exists "$name" "$proj"; then
    _secret_err "not found: $proj/$name (use 'secret set' to create it)"
    return 1
  fi
  if (( ! want_value && ! from_stdin && ! comment_set && ! kind_set )); then
    _secret_err "update: nothing to do (use --value/--stdin, -j COMMENT, -D KIND)"
    return 2
  fi

  # merge with current metadata
  local row
  row=$(_secret_rows "$proj" | awk -F'\t' -v n="$name" '$2 == n { print; exit }')
  local -a f
  f=("${(@ps:\t:)row}")
  (( kind_set )) || kind=${f[4]}
  (( comment_set )) || comment=${f[5]}

  if (( from_stdin )) || ( (( want_value )) && [[ ! -t 0 ]] ); then
    _secret_store "$name" "$proj" "$comment" "$kind" || return 1
  else
    local value
    if (( want_value )); then
      value=$(_secret_prompt_value "$proj/$name") || return 1
    else
      value=$(_secret_get_value "$name" "$proj") || {
        _secret_err "cannot read current value of $proj/$name"; return 1
      }
    fi
    print -r -- "$value" | _secret_store "$name" "$proj" "$comment" "$kind" || return 1
  fi

  local -a parts
  (( want_value || from_stdin )) && parts+=(value)
  (( comment_set )) && parts+=(comment)
  (( kind_set )) && parts+=(kind)
  local lbl
  lbl=$(_secret_kc_label "$proj")
  print -r -- "updated $proj/$name (${(j:, :)parts})${lbl:+ [keychain: $lbl]}"
}

_secret_cmd_get() {
  local name="" proj="" copy=0
  while (( $# )); do
    case $1 in
      -p) proj=$2; shift 2 ;;
      -c|--copy) copy=1; shift ;;
      -*) _secret_err "get: unknown option '$1'"; return 2 ;;
      *) name=$1; shift ;;
    esac
  done
  [[ -z $name ]] && { _secret_err "get: NAME required"; return 2 }
  proj=$(_secret_resolve_project "$proj")
  local v
  if ! v=$(_secret_get_value "$name" "$proj"); then
    _secret_err "not found: $proj/$name"; return 1
  fi
  if (( copy )); then
    _secret_clip "$v"
    print -r -- "copied $proj/$name to clipboard (clears in 45s)"
  else
    print -r -- "$v"
  fi
}

_secret_cmd_show() {
  local name="" proj=""
  while (( $# )); do
    case $1 in
      -p) proj=$2; shift 2 ;;
      -*) _secret_err "show: unknown option '$1'"; return 2 ;;
      *) name=$1; shift ;;
    esac
  done
  [[ -z $name ]] && { _secret_err "show: NAME required"; return 2 }
  proj=$(_secret_resolve_project "$proj")
  local row
  row=$(_secret_rows "$proj" | awk -F'\t' -v n="$name" '$2 == n { print; exit }')
  [[ -z $row ]] && { _secret_err "not found: $proj/$name"; return 1 }
  local -a f
  f=("${(@ps:\t:)row}")
  printf '%-10s %s\n' \
    'Name:'     "${f[2]}" \
    'Project:'  "${f[1]}" \
    'Label:'    "${f[3]}" \
    'Kind:'     "${f[4]}" \
    'Comment:'  "${f[5]}" \
    'Modified:' "$(_secret_fmt_date "${f[6]}")" \
    'Keychain:' "$(_secret_kc_for "$proj")"
}

_secret_cmd_ls() {
  local proj="" long=0
  while (( $# )); do
    case $1 in
      -p) proj=$2; shift 2 ;;
      -l|--long) long=1; shift ;;
      -*) _secret_err "ls: unknown option '$1'"; return 2 ;;
      *) _secret_err "ls: unexpected argument '$1'"; return 2 ;;
    esac
  done
  proj=$(_secret_resolve_project "$proj")
  local rows
  rows=$(_secret_rows "$proj")
  [[ -z $rows ]] && { print -r -- "no secrets in project '$proj'" >&2; return 0 }
  if (( long )); then
    local row
    local -a f
    printf '%-32s %-14s %-17s %s\n' 'NAME' 'KIND' 'MODIFIED' 'COMMENT'
    while IFS= read -r row; do
      f=("${(@ps:\t:)row}")
      printf '%-32s %-14s %-17s %s\n' "${f[2]}" "${f[4]}" "$(_secret_fmt_date "${f[6]}")" "${f[5]}"
    done <<< "$rows"
  else
    print -r -- "$rows" | cut -f2
  fi
}

_secret_cmd_projects() {
  {
    _secret_dump_items | cut -f1
    # auto-mapped custom keychains are valid targets too (names only,
    # never dumped here, so locked ones do not trigger unlock prompts)
    if (( ! _kc_explicit )); then
      local f base
      for f in "${_kc_sl[@]}"; do
        [[ $f == $HOME/Library/Keychains/*.keychain-db ]] || continue
        [[ $f == "$_kc_default" ]] && continue
        base=${${f:t}%.keychain-db}
        [[ $base == login ]] && continue
        print -r -- "$base"
      done
    fi
  } | sort -u
}

_secret_cmd_env() {
  local proj=""
  while (( $# )); do
    case $1 in
      -p) proj=$2; shift 2 ;;
      -*) _secret_err "env: unknown option '$1'"; return 2 ;;
      *) _secret_err "env: unexpected argument '$1'"; return 2 ;;
    esac
  done
  proj=$(_secret_resolve_project "$proj")
  local row v
  local -a f
  _secret_rows "$proj" | while IFS= read -r row; do
    f=("${(@ps:\t:)row}")
    if ! v=$(_secret_get_value "${f[2]}" "${f[1]}"); then
      _secret_err "skipped ${f[1]}/${f[2]} (unreadable)"; continue
    fi
    print -r -- "export ${f[2]}=${(qq)v}"
  done
}

_secret_cmd_rm() {
  local name="" proj="" force=0
  while (( $# )); do
    case $1 in
      -p) proj=$2; shift 2 ;;
      -f|--force) force=1; shift ;;
      -*) _secret_err "rm: unknown option '$1'"; return 2 ;;
      *) name=$1; shift ;;
    esac
  done
  [[ -z $name ]] && { _secret_err "rm: NAME required"; return 2 }
  proj=$(_secret_resolve_project "$proj")
  _secret_exists "$name" "$proj" || { _secret_err "not found: $proj/$name"; return 1 }
  if (( ! force )) && [[ -t 0 ]]; then
    local reply
    if ! read -q "reply?delete $proj/$name? [y/N] "; then print '' >&2; return 1; fi
    print '' >&2
  fi
  if _secret_delete "$name" "$proj"; then
    local lbl
    lbl=$(_secret_kc_label "$proj")
    print -r -- "deleted $proj/$name${lbl:+ [keychain: $lbl]}"
  else
    _secret_err "failed to delete $proj/$name"; return 1
  fi
}

_secret_export_json() {        # $1 project ("" = all); JSON document on stdout
  local row v
  local -a f
  _secret_rows "$1" | while IFS= read -r row; do
    f=("${(@ps:\t:)row}")
    v=$(_secret_get_value "${f[2]}" "${f[1]}") || continue
    print -r -- "$v" | jq -Rc \
      --arg project "${f[1]}" --arg name "${f[2]}" --arg kind "${f[4]}" --arg comment "${f[5]}" \
      '{project: $project, name: $name, kind: $kind, comment: $comment, value: .}'
  done | jq -s --arg exported "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{version: 1, exported: $exported, items: .}'
}

_secret_export_env() {         # $1 project ("" = all); export lines on stdout
  local row v last=""
  local -a f
  _secret_rows "$1" | while IFS= read -r row; do
    f=("${(@ps:\t:)row}")
    v=$(_secret_get_value "${f[2]}" "${f[1]}") || continue
    if [[ -z $1 && ${f[1]} != $last ]]; then
      print -r -- "# === project: ${f[1]} ==="
      last=${f[1]}
    fi
    print -r -- "export ${f[2]}=${(qq)v}"
  done
}

_secret_cmd_export() {
  local proj="" all=0 out="" fmt=""
  while (( $# )); do
    case $1 in
      -p) proj=$2; shift 2 ;;
      --all) all=1; shift ;;
      -o) out=$2; shift 2 ;;
      --format) fmt=$2; shift 2 ;;
      --age) fmt=age; shift ;;
      --json) fmt=json; shift ;;
      --env|--plain) fmt=env; shift ;;
      *) _secret_err "export: unknown option '$1'"; return 2 ;;
    esac
  done
  if (( all )); then
    proj=""
  else
    proj=$(_secret_resolve_project "$proj")
  fi
  local rows
  rows=$(_secret_rows "$proj")
  [[ -z $rows ]] && { _secret_err "nothing to export (project: ${proj:-all})"; return 1 }

  if [[ -z $fmt && -n $out ]]; then
    case $out in
      *.age) fmt=age ;;
      *.json) fmt=json ;;
      *.env) fmt=env ;;
    esac
  fi
  : ${fmt:=age}
  case $fmt in
    age|json|env) ;;
    *) _secret_err "export: unknown format '$fmt' (age|json|env)"; return 2 ;;
  esac
  if [[ -z $out ]]; then
    local ext=$fmt
    [[ $fmt == age ]] && ext="json.age"
    out="secret-export-${proj:-all}-$(date +%Y%m%d).$ext"
  fi

  command -v jq >/dev/null 2>&1 || { _secret_err "jq is required (brew install jq)"; return 1 }
  case $fmt in
    age)
      command -v age >/dev/null 2>&1 || { _secret_err "age is required (brew install age)"; return 1 }
      _secret_export_json "$proj" | age ${=SECRET_AGE_ARGS:--p} -o "$out" || {
        _secret_err "age encryption failed"; return 1
      }
      ;;
    json)
      print -r -- "warning: '$out' will contain plaintext secrets" >&2
      _secret_export_json "$proj" > "$out" || return 1
      ;;
    env)
      print -r -- "warning: '$out' will contain plaintext secrets" >&2
      _secret_export_env "$proj" > "$out" || return 1
      ;;
  esac
  chmod 600 "$out"
  local count lbl=""
  [[ -n $proj ]] && lbl=$(_secret_kc_label "$proj")
  count=$(print -r -- "$rows" | wc -l | tr -d ' ')
  print -r -- "exported $count item(s) (project: ${proj:-all})${lbl:+ [keychain: $lbl]} -> $out"
}

_secret_cmd_import() {
  local file="" proj_flag="" yes=0
  while (( $# )); do
    case $1 in
      -p) proj_flag=$2; shift 2 ;;
      -y|--yes) yes=1; shift ;;
      -*) _secret_err "import: unknown option '$1'"; return 2 ;;
      *) file=$1; shift ;;
    esac
  done
  [[ -z $file ]] && { _secret_err "import: FILE required"; return 2 }
  [[ -r $file ]] || { _secret_err "cannot read '$file'"; return 1 }

  local content
  if [[ $file == *.age || "$(head -c 21 -- "$file" 2>/dev/null)" == "age-encryption.org/v1" ]]; then
    command -v age >/dev/null 2>&1 || { _secret_err "age is required (brew install age)"; return 1 }
    content=$(age -d ${=SECRET_AGE_DECRYPT_ARGS} -- "$file") || {
      _secret_err "decryption failed"; return 1
    }
  else
    content=$(<"$file")
  fi

  local -a names values projs comments kinds
  local trimmed=${content##[[:space:]]#}
  if [[ $trimmed == \{* || $trimmed == \[* ]]; then
    command -v jq >/dev/null 2>&1 || { _secret_err "jq is required (brew install jq)"; return 1 }
    local n v p c k
    while IFS=$'\t' read -r n v p c k; do
      names+=("$(_secret_tsv_unescape "$n")")
      values+=("$(_secret_tsv_unescape "$v")")
      projs+=("$(_secret_tsv_unescape "$p")")
      comments+=("$(_secret_tsv_unescape "$c")")
      kinds+=("$(_secret_tsv_unescape "$k")")
    done < <(print -r -- "$content" \
      | jq -r '.items[] | [.name, .value, (.project // ""), (.comment // ""), (.kind // "")] | @tsv') || true
  else
    local line n v
    while IFS= read -r line; do
      line=${line%$'\r'}
      [[ -z ${line//[[:space:]]/} ]] && continue
      line=${line##[[:space:]]#}
      [[ $line == \#* ]] && continue
      line=${line#export }
      [[ $line == *=* ]] || continue
      n=${line%%=*}
      v=${line#*=}
      n=${n%%[[:space:]]#}
      v=${(Q)v}
      names+=("$n"); values+=("$v"); projs+=(""); comments+=(""); kinds+=("")
    done <<< "$content"
  fi
  (( ${#names} )) || { _secret_err "no items found in '$file'"; return 1 }

  local base
  base=$(_secret_resolve_project "$proj_flag")
  local -a targets
  local i tp
  for (( i = 1; i <= ${#names}; i++ )); do
    if [[ -n $proj_flag ]]; then tp=$base
    elif [[ -n ${projs[i]} ]]; then tp=${projs[i]}
    else tp=$base
    fi
    targets+=("$tp")
  done

  local lbl
  print -r -- "importing ${#names} item(s):"
  for (( i = 1; i <= ${#names}; i++ )); do
    lbl=$(_secret_kc_label "${targets[i]}")
    print -r -- "  ${targets[i]}/${names[i]}${lbl:+ [kc:$lbl]}"
  done
  if (( ! yes )) && [[ -t 0 && -t 1 ]]; then
    local reply
    if ! read -q "reply?proceed? [y/N] "; then print '' >&2; return 1; fi
    print '' >&2
  fi

  local ok=0 fail=0
  for (( i = 1; i <= ${#names}; i++ )); do
    if ! _secret_check_name "${names[i]}" || ! _secret_check_project "${targets[i]}"; then
      (( fail++ )); continue
    fi
    if print -r -- "${values[i]}" \
        | _secret_store "${names[i]}" "${targets[i]}" "${comments[i]}" "${kinds[i]}"; then
      (( ok++ ))
    else
      (( fail++ ))
    fi
  done
  print -r -- "imported $ok item(s)$( (( fail )) && print -rn -- ", $fail failed" )"
  (( fail == 0 ))
}

# ---------------------------------------------------- keychain management --

_secret_kc_searchlist() {      # user-domain search list, one path per line
  security list-keychains -d user 2>/dev/null \
    | sed -E 's/^[[:space:]]*"(.*)"[[:space:]]*$/\1/'
}

_secret_kc_customs() {         # registered custom keychain paths, one per line
  local f short
  for f in "${_kc_sl[@]}"; do
    [[ $f == $HOME/Library/Keychains/*.keychain-db ]] || continue
    [[ $f == "$_kc_default" ]] && continue
    short=${${f:t}%.keychain-db}
    [[ $short == login ]] && continue
    if [[ -n $SECRET_TEST_ONLY_KC ]]; then
      [[ $short == ${~SECRET_TEST_ONLY_KC} ]] || continue
    fi
    print -r -- "$f"
  done
}

# Validate a keychain password. The keychain must be locked for macOS to
# actually check it, so this locks first; a WRONG password leaves the
# keychain locked (callers report that). Exit 0 = password is correct.
_secret_kc_try_pw() {          # $1 keychain  $2 password
  security lock-keychain "$1" 2>/dev/null
  print -r -- "unlock-keychain -p $(_secret_quote_si "$2") $(_secret_quote_si "$1")" \
    | security -i >/dev/null 2>&1
}

_secret_master_get() {         # master password on stdout (fails if not stored)
  security find-generic-password -s 'keychain-password' \
    -a "$(_secret_master_account)" -w "$_kc_default" 2>/dev/null
}

_secret_master_store() {       # $1 password; store/update the master item in login
  local macct
  macct=$(_secret_master_account)
  local cmd="add-generic-password -U"
  cmd+=" -a $(_secret_quote_si "$macct")"
  cmd+=" -s \"keychain-password\""
  cmd+=" -l $(_secret_quote_si "keychain-password/$macct")"
  cmd+=" -D \"keychain password\""
  cmd+=" -j \"master password for secret.zsh custom keychains\""
  cmd+=" -w $(_secret_quote_si "$1")"
  cmd+=" $(_secret_quote_si "$_kc_default")"
  print -r -- "$cmd" | security -i >/dev/null 2>&1
  security find-generic-password -s 'keychain-password' -a "$macct" \
    "$_kc_default" >/dev/null 2>&1
}

_secret_kc_create() {
  local name="" timeout_min=30 autolock=1
  while (( $# )); do
    case $1 in
      --timeout) timeout_min=$2; shift 2 ;;
      --no-autolock) autolock=0; shift ;;
      -*) _secret_err "keychain create: unknown option '$1'"; return 2 ;;
      *) name=$1; shift ;;
    esac
  done
  [[ -z $name ]] && { _secret_err "keychain create: NAME required"; return 2 }
  [[ $name == default || $name == login || $name == "$(_secret_master_account)" ]] \
    && { _secret_err "'$name' is reserved"; return 2 }
  _secret_check_project "$name" || return 2
  [[ $timeout_min == <-> && $timeout_min -gt 0 ]] || {
    _secret_err "keychain create: --timeout expects minutes (integer)"; return 2
  }
  local kcpath=$HOME/Library/Keychains/$name.keychain-db
  [[ -e $kcpath ]] && { _secret_err "keychain already exists: $kcpath"; return 1 }
  local mpw used_master=0
  mpw=$(_secret_master_get)
  if [[ -n $mpw ]]; then
    # master password set: create with it, no prompt (argv-free via security -i)
    print -r -- "create-keychain -p $(_secret_quote_si "$mpw") $(_secret_quote_si "$kcpath")" \
      | security -i >/dev/null 2>&1
    [[ -e $kcpath ]] || { _secret_err "create failed"; return 1 }
    used_master=1
  else
    if [[ ! -t 0 ]]; then
      _secret_err "keychain create is interactive (password prompt needs a terminal)"
      return 1
    fi
    # password is prompted (hidden, confirmed) by security itself — never in argv
    security create-keychain "$kcpath" || { _secret_err "create failed"; return 1 }
  fi
  if (( autolock )); then
    security set-keychain-settings -l -u -t $(( timeout_min * 60 )) "$kcpath" \
      || _secret_err "warning: could not apply auto-lock settings"
  fi
  # append to the search list so Keychain Access and `security` can see it
  local -a sl
  sl=(${(@f)$(_secret_kc_searchlist)})
  if (( ! ${sl[(Ie)$kcpath]} )); then
    security list-keychains -d user -s "${sl[@]}" "$kcpath" \
      || _secret_err "warning: could not add to the keychain search list"
  fi
  print -r -- "created keychain '$name' ($kcpath)"
  (( used_master )) && print -r -- "password: master (unlocks with the master password)"
  if (( autolock )); then
    print -r -- "auto-lock: on sleep and after ${timeout_min} min idle"
  else
    print -r -- "auto-lock: disabled"
  fi
  if [[ $name == global ]]; then
    print -r -- "this is now the base keychain: all secrets without their own"
    print -r -- "project keychain are stored here instead of the login keychain"
  else
    print -r -- "secrets with project '$name' will now be stored there automatically"
  fi
}

_secret_kc_ls() {
  local -a sl
  sl=(${(@f)$(_secret_kc_searchlist)})
  local f base flags
  for f in $HOME/Library/Keychains/*.keychain-db(N); do
    base=${${f:t}%.keychain-db}
    flags=""
    [[ $f == "$_kc_default" ]] && flags+=" (default)"
    (( ${sl[(Ie)$f]} )) && flags+=" (search list)"
    if (( ! _kc_explicit )) && [[ $f == "$_kc" && $f != "$_kc_default" ]]; then
      flags+=" (secret base)"
    fi
    print -r -- "$base$flags"
  done
}

_secret_kc_info() {
  local name=$1
  [[ -z $name ]] && { _secret_err "keychain info: NAME required"; return 2 }
  local kcpath
  kcpath=$(_secret_resolve_keychain "$name")
  [[ -e $kcpath ]] || { _secret_err "no such keychain: $name"; return 1 }
  print -r -- "path:        $kcpath"
  [[ $kcpath == "$_kc_default" ]] && print -r -- "default:     yes"
  local -a sl
  sl=(${(@f)$(_secret_kc_searchlist)})
  (( ${sl[(Ie)$kcpath]} )) && print -r -- "search list: yes" || print -r -- "search list: no"
  local settings
  if settings=$(security show-keychain-info "$kcpath" 2>&1); then
    print -r -- "settings:    ${settings#Keychain *\" }"
  else
    print -r -- "settings:    (unavailable — keychain may be locked)"
  fi
}

_secret_kc_lock() {
  if [[ $1 == --all || $1 == -a ]]; then
    security lock-keychain -a && print -r -- "locked all keychains"
    return
  fi
  [[ -z $1 ]] && { _secret_err "keychain lock: NAME or --all required"; return 2 }
  local kcpath
  kcpath=$(_secret_resolve_keychain "$1")
  [[ -e $kcpath ]] || { _secret_err "no such keychain: $1"; return 1 }
  security lock-keychain "$kcpath" && print -r -- "locked $1"
}

_secret_kc_unlock() {
  [[ -z $1 ]] && { _secret_err "keychain unlock: NAME required"; return 2 }
  local kcpath
  kcpath=$(_secret_resolve_keychain "$1")
  [[ -e $kcpath ]] || { _secret_err "no such keychain: $1"; return 1 }
  # password prompted by security itself (hidden) — never in argv
  security unlock-keychain "$kcpath" && print -r -- "unlocked $1"
}

_secret_kc_remember() {        # NAME [--stdin]: store keychain password in login
  local name="" from_stdin=0
  while (( $# )); do
    case $1 in
      --stdin) from_stdin=1; shift ;;
      -*) _secret_err "keychain remember: unknown option '$1'"; return 2 ;;
      *) name=$1; shift ;;
    esac
  done
  [[ -z $name ]] && { _secret_err "keychain remember: NAME required"; return 2 }
  [[ $name == "$(_secret_master_account)" ]] && {
    _secret_err "'$name' is the master account (use: secret keychain master set)"; return 2
  }
  local kcpath
  kcpath=$(_secret_resolve_keychain "$name")
  [[ -e $kcpath ]] || { _secret_err "no such keychain: $name"; return 1 }
  [[ $kcpath == "$_kc_default" ]] && {
    _secret_err "refusing: that is the default keychain itself"; return 1
  }
  local short=${${kcpath:t}%.keychain-db}
  local pw
  if (( from_stdin )) || [[ ! -t 0 ]]; then
    IFS= read -r pw
  else
    IFS= read -rs "pw?password of keychain '$short' (hidden): " || { print '' >&2; return 1 }
    print '' >&2
  fi
  # verify the password: lock, then unlock with it (argv-free via security -i)
  security lock-keychain "$kcpath" 2>/dev/null
  if ! print -r -- "unlock-keychain -p $(_secret_quote_si "$pw") $(_secret_quote_si "$kcpath")" \
      | security -i >/dev/null 2>&1; then
    _secret_err "wrong password for '$short' (keychain left locked)"
    return 1
  fi
  # store in the login keychain (service "keychain-password", account NAME)
  local cmd="add-generic-password -U"
  cmd+=" -a $(_secret_quote_si "$short")"
  cmd+=" -s \"keychain-password\""
  cmd+=" -l $(_secret_quote_si "keychain-password/$short")"
  cmd+=" -D \"keychain password\""
  cmd+=" -j \"unlock password used by secret.zsh auto-unlock\""
  cmd+=" -w $(_secret_quote_si "$pw")"
  cmd+=" $(_secret_quote_si "$_kc_default")"
  print -r -- "$cmd" | security -i >/dev/null 2>&1
  if ! security find-generic-password -s 'keychain-password' -a "$short" \
      "$_kc_default" >/dev/null 2>&1; then
    _secret_err "failed to store the password in the login keychain"
    return 1
  fi
  print -r -- "stored password for '$short' in the login keychain"
  print -r -- "secret will now unlock it automatically when needed"
}

_secret_kc_forget() {          # NAME: remove the stored keychain password
  [[ -z $1 ]] && { _secret_err "keychain forget: NAME required"; return 2 }
  local short=$1
  short=${${short:t}%.keychain-db}
  if security delete-generic-password -s 'keychain-password' -a "$short" \
      "$_kc_default" >/dev/null 2>&1; then
    print -r -- "forgot stored password for '$short'"
  else
    _secret_err "no stored password for '$short'"
    return 1
  fi
}

_secret_kc_rm() {
  local name="" force=0
  while (( $# )); do
    case $1 in
      -f|--force) force=1; shift ;;
      -*) _secret_err "keychain rm: unknown option '$1'"; return 2 ;;
      *) name=$1; shift ;;
    esac
  done
  [[ -z $name ]] && { _secret_err "keychain rm: NAME required"; return 2 }
  local kcpath
  kcpath=$(_secret_resolve_keychain "$name")
  [[ -e $kcpath ]] || { _secret_err "no such keychain: $name"; return 1 }
  [[ $kcpath == "$_kc_default" ]] && { _secret_err "refusing to delete the default keychain"; return 1 }
  if (( ! force )); then
    if [[ ! -t 0 ]]; then
      _secret_err "keychain rm needs a terminal to confirm (or pass -f)"
      return 1
    fi
    local reply
    if ! read -q "reply?delete keychain '$name' and ALL items in it? [y/N] "; then
      print '' >&2; return 1
    fi
    print '' >&2
  fi
  security delete-keychain "$kcpath" || { _secret_err "delete failed"; return 1 }
  # drop any stored unlock password for it
  security delete-generic-password -s 'keychain-password' \
    -a "${${kcpath:t}%.keychain-db}" "$_kc_default" >/dev/null 2>&1
  print -r -- "deleted keychain $name"
}

_secret_kc_register() {        # add an existing .keychain-db to the search list
  [[ -z $1 ]] && { _secret_err "keychain register: NAME required"; return 2 }
  local kcpath
  kcpath=$(_secret_resolve_keychain "$1")
  [[ -e $kcpath ]] || { _secret_err "no such keychain file: $1"; return 1 }
  local -a sl
  sl=(${(@f)$(_secret_kc_searchlist)})
  if (( ${sl[(Ie)$kcpath]} )); then
    print -r -- "already registered: ${${kcpath:t}%.keychain-db}"
    return 0
  fi
  security list-keychains -d user -s "${sl[@]}" "$kcpath" \
    || { _secret_err "could not update the search list"; return 1 }
  print -r -- "registered ${${kcpath:t}%.keychain-db} in the search list"
}

_secret_master_set() {
  local from_stdin=0
  while (( $# )); do
    case $1 in
      --stdin) from_stdin=1; shift ;;
      *) _secret_err "keychain master set: unknown option '$1'"; return 2 ;;
    esac
  done
  local pw
  if (( from_stdin )) || [[ ! -t 0 ]]; then
    IFS= read -r pw
  else
    pw=$(_secret_prompt_value "the master (all custom keychains)") || return 1
  fi
  [[ -n $pw ]] || { _secret_err "empty master password, aborted"; return 1 }

  local kc short cur
  local -a adopted skipped failed
  for kc in ${(f)"$(_secret_kc_customs)"}; do
    [[ -n $kc ]] || continue
    short=${${kc:t}%.keychain-db}
    # already on the master password?
    if _secret_kc_try_pw "$kc" "$pw"; then
      adopted+=("$short")
      security delete-generic-password -s 'keychain-password' -a "$short" \
        "$_kc_default" >/dev/null 2>&1
      continue
    fi
    # find its current password: stored item, else ask
    cur=$(security find-generic-password -s 'keychain-password' -a "$short" \
          -w "$_kc_default" 2>/dev/null)
    if [[ -z $cur ]] && (( ! from_stdin )) && [[ -t 0 ]]; then
      IFS= read -rs "cur?current password of '$short' (hidden, Enter to skip): "
      print '' >&2
    fi
    if [[ -z $cur ]]; then
      _secret_kc_ensure "$kc"   # restore unlock if an item exists
      skipped+=("$short")
      continue
    fi
    if ! _secret_kc_try_pw "$kc" "$cur"; then
      _secret_err "wrong current password for '$short' (left locked)"
      failed+=("$short")
      continue
    fi
    if print -r -- "set-keychain-password -o $(_secret_quote_si "$cur") -p $(_secret_quote_si "$pw") $(_secret_quote_si "$kc")" \
        | security -i >/dev/null 2>&1 && _secret_kc_try_pw "$kc" "$pw"; then
      adopted+=("$short")
      security delete-generic-password -s 'keychain-password' -a "$short" \
        "$_kc_default" >/dev/null 2>&1
    else
      failed+=("$short")
    fi
  done

  _secret_master_store "$pw" \
    || { _secret_err "failed to store the master password in login"; return 1 }
  print -r -- "master password stored in the login keychain"
  (( ${#adopted} )) && print -r -- "adopted: ${(j:, :)adopted}"
  (( ${#skipped} )) && print -r -- "skipped (current password unknown): ${(j:, :)skipped}"
  (( ${#failed} ))  && print -r -- "FAILED: ${(j:, :)failed}"
  print -r -- "keep this password in your password manager — it is the recovery key"
  (( ${#failed} == 0 ))
}

_secret_master_rotate() {
  local from_stdin=0
  [[ $1 == --stdin ]] && { from_stdin=1; shift }
  local old new
  old=$(_secret_master_get) || {
    _secret_err "no master password stored (run: secret keychain master set)"; return 1
  }
  if (( from_stdin )) || [[ ! -t 0 ]]; then
    IFS= read -r new
  else
    new=$(_secret_prompt_value "the NEW master") || return 1
  fi
  [[ -n $new ]] || { _secret_err "empty master password, aborted"; return 1 }

  local kc short
  local -a rotated notmaster failed
  for kc in ${(f)"$(_secret_kc_customs)"}; do
    [[ -n $kc ]] || continue
    short=${${kc:t}%.keychain-db}
    if ! _secret_kc_try_pw "$kc" "$old"; then
      _secret_kc_ensure "$kc"   # not on master; restore unlock if possible
      notmaster+=("$short")
      continue
    fi
    if print -r -- "set-keychain-password -o $(_secret_quote_si "$old") -p $(_secret_quote_si "$new") $(_secret_quote_si "$kc")" \
        | security -i >/dev/null 2>&1 && _secret_kc_try_pw "$kc" "$new"; then
      rotated+=("$short")
    else
      failed+=("$short")
    fi
  done
  _secret_master_store "$new" \
    || { _secret_err "failed to update the master item in login"; return 1 }
  print -r -- "master password rotated"
  (( ${#rotated} ))   && print -r -- "rotated: ${(j:, :)rotated}"
  (( ${#notmaster} )) && print -r -- "not on master (untouched): ${(j:, :)notmaster}"
  (( ${#failed} ))    && print -r -- "FAILED: ${(j:, :)failed}"
  print -r -- "update your password manager with the new value"
  (( ${#failed} == 0 ))
}

_secret_master_status() {
  local macct
  macct=$(_secret_master_account)
  if security find-generic-password -s 'keychain-password' -a "$macct" \
      "$_kc_default" >/dev/null 2>&1; then
    print -r -- "master: stored in login"
  else
    print -r -- "master: not set"
  fi
  local kc short src state
  printf '%-26s %-12s %s\n' 'KEYCHAIN' 'UNLOCK VIA' 'STATE'
  for kc in ${(f)"$(_secret_kc_customs)"}; do
    [[ -n $kc ]] || continue
    short=${${kc:t}%.keychain-db}
    if security find-generic-password -s 'keychain-password' -a "$short" \
        "$_kc_default" >/dev/null 2>&1; then
      src=individual
    elif security find-generic-password -s 'keychain-password' -a "$macct" \
        "$_kc_default" >/dev/null 2>&1; then
      src=master
    else
      src='none (prompts)'
    fi
    security show-keychain-info "$kc" >/dev/null 2>&1 && state=unlocked || state=locked
    printf '%-26s %-12s %s\n' "$short" "$src" "$state"
  done
}

_secret_master_reveal() {
  local copy=0
  [[ $1 == -c || $1 == --copy ]] && copy=1
  local pw
  pw=$(_secret_master_get) || { _secret_err "no master password stored"; return 1 }
  if (( copy )); then
    _secret_clip "$pw"
    print -r -- "master password copied to clipboard (clears in 45s)"
  else
    print -r -- "$pw"
  fi
}

_secret_master_forget() {
  if security delete-generic-password -s 'keychain-password' \
      -a "$(_secret_master_account)" "$_kc_default" >/dev/null 2>&1; then
    print -r -- "master password removed from login (keychain passwords unchanged;"
    print -r -- "keep the master in your password manager — access will prompt now)"
  else
    _secret_err "no master password stored"
    return 1
  fi
}

_secret_cmd_master() {
  local sub=${1:-status}
  (( $# )) && shift
  case $sub in
    set)    _secret_master_set "$@" ;;
    rotate) _secret_master_rotate "$@" ;;
    status) _secret_master_status ;;
    reveal) _secret_master_reveal "$@" ;;
    forget) _secret_master_forget ;;
    *) _secret_err "keychain master: unknown subcommand '$sub' (set|rotate|status|reveal|forget)"; return 2 ;;
  esac
}

_secret_cmd_keychain() {
  local sub=${1:-ls}
  (( $# )) && shift
  case $sub in
    create)    _secret_kc_create "$@" ;;
    ls|list)   _secret_kc_ls ;;
    info)      _secret_kc_info "$@" ;;
    lock)      _secret_kc_lock "$@" ;;
    unlock)    _secret_kc_unlock "$@" ;;
    remember)  _secret_kc_remember "$@" ;;
    forget)    _secret_kc_forget "$@" ;;
    register)  _secret_kc_register "$@" ;;
    master)    _secret_cmd_master "$@" ;;
    rm|delete) _secret_kc_rm "$@" ;;
    *) _secret_err "keychain: unknown subcommand '$sub' (create|ls|info|lock|unlock|remember|forget|register|master|rm)"; return 2 ;;
  esac
}

_secret_cmd_help() {
  cat <<'EOF'
secret — manage secrets in the macOS Keychain

USAGE
  secret                                    interactive wizard (fzf)
  secret [-k KEYCHAIN] <command> [args]

COMMANDS
  set NAME [-p proj] [-j comment] [-D kind] [--stdin]
        store a secret; prompts for the value (no echo), or reads one
        line from stdin with --stdin / when piped
  update NAME [-p proj] [-j comment] [-D kind] [--value|--stdin]
        partially update an existing secret: --value prompts for a new
        value (--stdin reads it from stdin), -j/-D replace comment/kind
        (-j '' clears the comment); everything else is kept as-is
  get NAME [-p proj] [-c|--copy]
        print the value (or copy to clipboard, auto-clears in 45s)
  show NAME [-p proj]      metadata only (never prints the value)
  ls [-p proj] [-l|--long] list secrets in a project
  projects                 list all projects
  env [-p proj]            emit `export NAME=...` lines, e.g.:
                             eval "$(secret env -p myproj)"
  rm NAME [-p proj] [-f]   delete a secret
  export [-p proj|--all] [-o FILE] [--format age|json|env]
        write secrets to a file; age (encrypted JSON, default), json,
        or env (plaintext export lines, metadata lost)
  import FILE [-p proj] [-y]
        load secrets from .json.age / .json / .env files; -p forces all
        items into one project, otherwise JSON items keep their own
  keychain create NAME [--timeout MIN] [--no-autolock]
        create ~/Library/Keychains/NAME.keychain-db (auto-locks on sleep
        and after 30 min by default) and add it to the search list
  keychain master set|rotate [--stdin]|status|reveal [-c]|forget
        ONE password for every custom keychain: `set` rotates all
        registered custom keychains to the master password and stores it
        in login for auto-unlock; keep that password in your password
        manager — it is the recovery key for every .keychain-db file.
        With a master set, `keychain create` needs no password prompt.
  keychain remember NAME [--stdin]
        store NAME's own unlock password in the login keychain (per-
        keychain override; takes precedence over the master)
  keychain register NAME
        add an existing .keychain-db (e.g. copied from another Mac) to
        the search list so auto-mapping sees it
  keychain ls|info NAME|lock NAME|--all|unlock NAME|forget NAME|rm NAME [-f]
        manage custom keychains
  help                     this help

PROJECTS
  -p flag > basename of the enclosing git repo > "global".
  Stored as keychain attributes: service "secret.<project>", account NAME,
  plus label, kind (-D) and comment (-j) — all visible in Keychain Access.

KEYCHAINS
  Resolution order (per item, by project):
    1. -k NAME|PATH override (`-k default` = the system default keychain)
    2. ~/Library/Keychains/<project>.keychain-db   per-project mapping
    3. ~/Library/Keychains/global.keychain-db      preferred base
    4. the system default keychain (login)
  Steps 2-3 require the keychain to be registered in the user search
  list (`secret keychain create` does that automatically; app/system
  keychain files you never registered are not mapped).
  Run `secret keychain create global` once to keep all secrets out of
  the login keychain.
  Listing commands (projects, export --all) enumerate the base keychain
  plus registered custom keychain names; locked keychains are never
  dumped unasked.
EOF
}

# ----------------------------------------------------------------- fzf UI --

_secret_fzf() {
  fzf --height=40% --reverse --no-sort "$@"
}

_secret_ui_pick_project() {    # $1 header  $2.. extra entries; selection on stdout
  local header=$1; shift
  local cur
  cur=$(_secret_resolve_project "")
  local -a existing extras
  extras=("$@")
  existing=(${(@f)$(_secret_cmd_projects)})
  if (( ${existing[(Ie)$cur]} )); then
    existing=("$cur" ${existing:#$cur})
  fi
  local -a items
  items=(${extras:#} $existing)
  (( ${#items} )) || { _secret_err "no projects yet — use 'secret set' or the Add action first"; return 1 }
  print -rl -- "${items[@]}" | _secret_fzf --header="$header" --prompt='project> '
}

_secret_ui_pick_items() {      # $1 project  $2 header  $3 "multi"|""; names on stdout
  local rows
  rows=$(_secret_rows "$1")
  [[ -z $rows ]] && { _secret_err "no secrets in project '$1'"; return 1 }
  local row lines=""
  local -a f
  while IFS= read -r row; do
    f=("${(@ps:\t:)row}")
    lines+="$(printf '%-32s %-14s %-17s %s' "${f[2]}" "${f[4]}" "$(_secret_fmt_date "${f[6]}")" "${f[5]}")"$'\n'
  done <<< "$rows"
  local -a fzopts
  [[ $3 == multi ]] && fzopts+=(--multi)
  print -rn -- "$lines" \
    | _secret_fzf "${fzopts[@]}" --header="$2" --prompt='secret> ' \
    | awk '{print $1}'
}

_secret_ui_get() {
  local proj name
  proj=$(_secret_ui_pick_project 'secret › get › choose project') || return 0
  [[ -z $proj ]] && return 0
  name=$(_secret_ui_pick_items "$proj" "secret › $proj$(_secret_kc_suffix "$proj") › get (copies to clipboard)") || return 0
  [[ -z $name ]] && return 0
  _secret_cmd_get "$name" -p "$proj" --copy
}

_secret_ui_add() {
  local proj name kind comment
  proj=$(_secret_ui_pick_project 'secret › add › choose project' '[+ new project]') || return 0
  [[ -z $proj ]] && return 0
  if [[ $proj == '[+ new project]' ]]; then
    read -r "proj?new project name: " || return 0
    proj=${${proj##[[:space:]]#}%%[[:space:]]#}
    _secret_check_project "$proj" || return 1
  fi
  while true; do
    read -r "name?variable name (e.g. STRIPE_KEY): " || return 0
    _secret_check_name "$name" && break
  done
  kind=$(printf '%s\n' 'ENV' 'api key' 'token' 'password' 'webhook secret' '[custom]' \
    | _secret_fzf --header="secret › $proj/$name › kind" --prompt='kind> ') || return 0
  if [[ $kind == '[custom]' ]]; then
    read -r "kind?kind: " || return 0
  fi
  read -r "comment?comment (optional): " || return 0
  local -a args
  args=("$name" -p "$proj")
  [[ -n $kind ]] && args+=(-D "$kind")
  [[ -n $comment ]] && args+=(-j "$comment")
  _secret_cmd_set "${args[@]}"
}

_secret_ui_update() {
  local proj name fields fld c k
  proj=$(_secret_ui_pick_project 'secret › update › choose project') || return 0
  [[ -z $proj ]] && return 0
  name=$(_secret_ui_pick_items "$proj" "secret › $proj$(_secret_kc_suffix "$proj") › update") || return 0
  [[ -z $name ]] && return 0
  local row
  row=$(_secret_rows "$proj" | awk -F'\t' -v n="$name" '$2 == n { print; exit }')
  local -a f
  f=("${(@ps:\t:)row}")
  fields=$(printf '%s\n' \
      'value     change the secret value (hidden prompt)' \
      'comment   change the comment' \
      'kind      change the kind' \
    | _secret_fzf --multi \
        --header="secret › $proj/$name › what to update (TAB to multi-select)" \
        --prompt='update> ') || return 0
  [[ -z $fields ]] && return 0
  local -a args
  args=("$name" -p "$proj")
  for fld in ${(f)fields}; do
    case ${${(z)fld}[1]} in
      value)
        args+=(--value)
        ;;
      comment)
        print -r -- "current comment: ${f[5]:-(none)}"
        read -r "c?new comment (empty clears): " || return 0
        args+=(-j "$c")
        ;;
      kind)
        k=$(printf '%s\n' 'ENV' 'api key' 'token' 'password' 'webhook secret' '[custom]' \
          | _secret_fzf --header="secret › $proj/$name › new kind (current: ${f[4]:-ENV})" \
              --prompt='kind> ') || return 0
        if [[ $k == '[custom]' ]]; then
          read -r "k?kind: " || return 0
        fi
        [[ -z $k ]] && return 0
        args+=(-D "$k")
        ;;
    esac
  done
  _secret_cmd_update "${args[@]}"
}

_secret_ui_list() {
  local proj
  proj=$(_secret_ui_pick_project 'secret › list › choose project') || return 0
  [[ -z $proj ]] && return 0
  print -r -- "project: $proj$(_secret_kc_suffix "$proj")"
  _secret_cmd_ls -p "$proj" --long
}

_secret_ui_show() {
  local proj name
  proj=$(_secret_ui_pick_project 'secret › show › choose project') || return 0
  [[ -z $proj ]] && return 0
  name=$(_secret_ui_pick_items "$proj" "secret › $proj$(_secret_kc_suffix "$proj") › show") || return 0
  [[ -z $name ]] && return 0
  _secret_cmd_show "$name" -p "$proj"
}

_secret_ui_delete() {
  local proj names n
  proj=$(_secret_ui_pick_project 'secret › delete › choose project') || return 0
  [[ -z $proj ]] && return 0
  names=$(_secret_ui_pick_items "$proj" "secret › $proj$(_secret_kc_suffix "$proj") › delete (TAB to multi-select)" multi) || return 0
  [[ -z $names ]] && return 0
  print -r -- "selected:"
  for n in ${(f)names}; do print -r -- "  $proj/$n"; done
  local reply
  if ! read -q "reply?delete ${#${(f)names}} secret(s)? [y/N] "; then print '' >&2; return 0; fi
  print '' >&2
  for n in ${(f)names}; do
    _secret_cmd_rm "$n" -p "$proj" -f
  done
}

_secret_ui_export() {
  local proj fmt out
  proj=$(_secret_ui_pick_project 'secret › export › choose project' '[all projects]') || return 0
  [[ -z $proj ]] && return 0
  fmt=$(printf '%s\n' \
      'age    encrypted JSON, passphrase (recommended)' \
      'json   plaintext JSON, metadata kept' \
      'env    plaintext export lines, no metadata' \
    | _secret_fzf --header='secret › export › format' --prompt='format> ') || return 0
  fmt=${${(z)fmt}[1]}
  local ext=$fmt pname=$proj
  [[ $fmt == age ]] && ext="json.age"
  [[ $proj == '[all projects]' ]] && pname=all
  local def="secret-export-${pname}-$(date +%Y%m%d).$ext"
  read -r "out?output file [$def]: " || return 0
  out=${out:-$def}
  local -a args
  args=(--format "$fmt" -o "$out")
  if [[ $proj == '[all projects]' ]]; then
    args+=(--all)
  else
    args+=(-p "$proj")
  fi
  _secret_cmd_export "${args[@]}"
}

_secret_ui_import() {
  local file proj
  local -a cands
  cands=(*.env(N) *.json(N) *.age(N))
  file=$(print -rl -- "${cands[@]}" '[enter a path]' | grep -v '^$' \
    | _secret_fzf --header='secret › import › choose file' --prompt='file> ') || return 0
  [[ -z $file ]] && return 0
  if [[ $file == '[enter a path]' ]]; then
    read -r "file?file path: " || return 0
    file=${file/#\~\//$HOME/}
    [[ -z $file ]] && return 0
  fi
  proj=$(_secret_ui_pick_project 'secret › import › target project' \
    '[auto / as recorded in file]' '[+ new project]') || return 0
  [[ -z $proj ]] && return 0
  if [[ $proj == '[+ new project]' ]]; then
    read -r "proj?new project name: " || return 0
    proj=${${proj##[[:space:]]#}%%[[:space:]]#}
    _secret_check_project "$proj" || return 1
  fi
  local -a args
  args=("$file")
  [[ $proj != '[auto / as recorded in file]' ]] && args+=(-p "$proj")
  _secret_cmd_import "${args[@]}"
}

_secret_ui() {
  if ! command -v fzf >/dev/null 2>&1; then
    _secret_err "the interactive UI needs fzf (brew install fzf); CLI subcommands still work"
    return 1
  fi
  local choice
  choice=$(printf '%s\n' \
      'Get      copy a secret to the clipboard' \
      'Add      store a new secret' \
      'Update   change the value or metadata of a secret' \
      'List     list secrets in a project' \
      'Show     inspect metadata (never the value)' \
      'Delete   delete secrets (TAB to multi-select)' \
      'Export   write secrets to a file (age/json/env)' \
      'Import   load secrets from a file' \
    | _secret_fzf --header='secret › choose an action' --prompt='action> ') || return 0
  [[ -z $choice ]] && return 0
  case ${${(z)choice}[1]:l} in
    get)    _secret_ui_get ;;
    add)    _secret_ui_add ;;
    update) _secret_ui_update ;;
    list)   _secret_ui_list ;;
    show)   _secret_ui_show ;;
    delete) _secret_ui_delete ;;
    export) _secret_ui_export ;;
    import) _secret_ui_import ;;
  esac
}

# ------------------------------------------------------------- dispatcher --

secret() {
  emulate -L zsh
  setopt local_options pipefail extended_glob
  local _kc_opt="" _kc_explicit=0
  while [[ $1 == -k || $1 == --keychain ]]; do
    [[ -n $2 ]] || { _secret_err "-k requires a keychain name or path"; return 2 }
    _kc_opt=$2
    _kc_explicit=1
    shift 2
  done
  local _kc _kc_default
  local -a _kc_sl
  _kc_default=$(_secret_default_keychain)
  _kc_sl=(${(@f)$(_secret_kc_searchlist)})
  if (( _kc_explicit )); then
    _kc=$(_secret_resolve_keychain "$_kc_opt")
  else
    # implicit base: prefer a registered global.keychain-db over login
    local _gkc=$HOME/Library/Keychains/global.keychain-db
    if [[ -e $_gkc ]] && (( ${_kc_sl[(Ie)$_gkc]} )); then
      _kc=$_gkc
    else
      _kc=$_kc_default
    fi
  fi
  [[ -n $_kc ]] || { _secret_err "could not resolve the target keychain"; return 1 }
  local cmd=${1:-}
  (( $# )) && shift
  case $cmd in
    '')             _secret_ui ;;
    ui)             _secret_ui ;;
    set)            _secret_cmd_set "$@" ;;
    update|edit)    _secret_cmd_update "$@" ;;
    get)            _secret_cmd_get "$@" ;;
    show)           _secret_cmd_show "$@" ;;
    ls|list)        _secret_cmd_ls "$@" ;;
    rm|del|delete)  _secret_cmd_rm "$@" ;;
    env)            _secret_cmd_env "$@" ;;
    export)         _secret_cmd_export "$@" ;;
    import)         _secret_cmd_import "$@" ;;
    projects)       _secret_cmd_projects ;;
    keychain|kc)    _secret_cmd_keychain "$@" ;;
    help|-h|--help) _secret_cmd_help ;;
    *)              _secret_err "unknown command '$cmd' (try: secret help)"; return 2 ;;
  esac
}
