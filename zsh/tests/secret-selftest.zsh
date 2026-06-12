#!/usr/bin/env zsh
# Round-trip self-test for secret.zsh.
# Uses the default keychain under throwaway projects "secret-selftest*",
# cleans up after itself. Values are test fixtures, not real secrets.
emulate -L zsh
setopt pipefail
source "$HOME/.config/zsh/functions/secret.zsh"

typeset -i fails=0
ok()  { print -r -- "ok   - $1"; }
bad() { print -r -- "FAIL - $1"; (( fails++ )); }

P=secret-selftest
P2=secret-selftest2
P3=secret-selftest3
TD=$(mktemp -d)

KCN=secret-selftest-kc
KCP=$HOME/Library/Keychains/$KCN.keychain-db
KCN2=secret-selftest-unlisted
KCP2=$HOME/Library/Keychains/$KCN2.keychain-db

# DKC = system default keychain; BKC = the tool's implicit base
# (global.keychain-db when registered, else DKC)
DKC=$(security default-keychain | sed -E 's/^[[:space:]]*"(.*)"[[:space:]]*$/\1/')
GKC=$HOME/Library/Keychains/global.keychain-db
slnow=(${(f)"$(security list-keychains -d user | sed -E 's/^[[:space:]]*"(.*)"[[:space:]]*$/\1/')"})
if [[ -e $GKC ]] && (( ${slnow[(Ie)$GKC]} )); then BKC=$GKC; else BKC=$DKC; fi

cleanup() {
  local p n
  security delete-keychain "$KCP" >/dev/null 2>&1
  security delete-keychain "$KCP2" >/dev/null 2>&1
  for p in $P $P2 $P3 $KCN $KCN2; do
    # enumerate both the base keychain and the system default: -k default
    # tests store into login even when the base is a custom keychain
    { secret ls -p $p 2>/dev/null; secret -k default ls -p $p 2>/dev/null } \
      | sort -u | while read -r n; do
      # delete every copy across the search list
      while security delete-generic-password -s "secret.$p" -a "$n" >/dev/null 2>&1; do :; done
    done
  done
  security delete-generic-password -s 'keychain-password' -a $KCN >/dev/null 2>&1
  security delete-generic-password -s 'keychain-password' -a $KCN2 >/dev/null 2>&1
  security delete-generic-password -s 'keychain-password' -a master-selftest >/dev/null 2>&1
  security delete-keychain "$HOME/Library/Keychains/secret-selftest-mkc.keychain-db" >/dev/null 2>&1
  rm -rf "$TD"
}
trap cleanup EXIT
cleanup 2>/dev/null   # in case of leftovers from a previous run
mkdir -p "$TD"

V1='sp ace "dq" \back\slash $dollar !bang '\''sq'\'' end'
V2='simple-token-123'

# --- set / get ---
print -r -- "$V1" | secret set TEST_ALPHA -p $P -j 'comment with "quotes" and spaces' -D 'api key' --stdin >/dev/null \
  && ok "set TEST_ALPHA (stdin)" || bad "set TEST_ALPHA (stdin)"
print -r -- "$V2" | secret set TEST_BETA -p $P --stdin >/dev/null \
  && ok "set TEST_BETA (stdin)" || bad "set TEST_BETA (stdin)"

[[ "$(secret get TEST_ALPHA -p $P)" == "$V1" ]] \
  && ok "get round-trips special chars" || bad "get round-trips special chars"
[[ "$(secret get TEST_BETA -p $P)" == "$V2" ]] \
  && ok "get simple value" || bad "get simple value"

# --- update (-U) ---
print -r -- 'updated-456' | secret set TEST_BETA -p $P --stdin >/dev/null
[[ "$(secret get TEST_BETA -p $P)" == 'updated-456' ]] \
  && ok "set -U updates existing item" || bad "set -U updates existing item"

# --- validation ---
print -r -- 'x' | secret set '1BAD' -p $P --stdin >/dev/null 2>&1 \
  && bad "rejects invalid name" || ok "rejects invalid name"
printf 'a\nb\n' | secret set TEST_MULTI -p $P --stdin >/dev/null 2>&1 \
  && bad "rejects multi-line value" || ok "rejects multi-line value"
secret get TEST_NOPE -p $P >/dev/null 2>&1 \
  && bad "get of missing item fails" || ok "get of missing item fails"

# --- ls / show / projects ---
lsout=$(secret ls -p $P)
lsarr=(${(f)lsout})
(( ${lsarr[(Ie)TEST_ALPHA]} )) && ok "ls lists item" || bad "ls lists item"
[[ ${#lsarr} -eq 2 ]] && ok "ls shows 2 items" || bad "ls shows 2 items"
longout=$(secret ls -p $P --long)
[[ $longout == *'api key'* ]] && ok "ls --long shows kind" || bad "ls --long shows kind"
[[ $longout =~ 'TEST_BETA[[:space:]]+ENV[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}' ]] \
  && ok "ls --long aligns columns for empty comment" || bad "ls --long aligns columns for empty comment"
showout=$(secret show TEST_ALPHA -p $P)
[[ $showout == *'comment with "quotes" and spaces'* ]] && ok "show displays comment" || bad "show displays comment"
[[ $showout =~ 'Modified:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}' ]] && ok "show displays modified date" || bad "show displays modified date"
[[ $showout != *$V1* ]] && ok "show never prints value" || bad "show never prints value"
[[ "$(print -r -- "$showout" | awk '/^Label:/ {print $2}')" == "$P/TEST_ALPHA" ]] \
  && ok "label prefixed in shared base keychain" || bad "label prefixed in shared base keychain"
projarr=(${(f)"$(secret projects)"})
(( ${projarr[(Ie)$P]} )) && ok "projects lists project" || bad "projects lists project"

# --- env / eval ---
envout=$(secret env -p $P)
( eval "$envout"; [[ "$TEST_ALPHA" == "$V1" && "$TEST_BETA" == 'updated-456' ]] ) \
  && ok "env output is eval-safe" || bad "env output is eval-safe"

# --- export json / import ---
secret export -p $P --format json -o "$TD/x.json" >/dev/null 2>&1 \
  && ok "export json" || bad "export json"
jq -e '.items | length == 2' "$TD/x.json" >/dev/null 2>&1 && ok "json has 2 items" || bad "json has 2 items"
jq -e '.items[] | select(.name == "TEST_ALPHA") | .kind == "api key"' "$TD/x.json" >/dev/null 2>&1 \
  && ok "json keeps metadata" || bad "json keeps metadata"
jq -e '.items[] | select(.name == "TEST_BETA") | .comment == ""' "$TD/x.json" >/dev/null 2>&1 \
  && ok "json empty comment stays empty" || bad "json empty comment stays empty"
[[ "$(stat -f %Lp "$TD/x.json" 2>/dev/null)" == 600 ]] && ok "export chmod 600" || bad "export chmod 600"

secret rm TEST_ALPHA -p $P -f >/dev/null && secret rm TEST_BETA -p $P -f >/dev/null
[[ -z "$(secret ls -p $P 2>/dev/null)" ]] && ok "rm removes items" || bad "rm removes items"

secret import "$TD/x.json" >/dev/null 2>&1 && ok "import json (project from file)" || bad "import json (project from file)"
[[ "$(secret get TEST_ALPHA -p $P)" == "$V1" ]] && ok "json round-trip value" || bad "json round-trip value"
[[ "$(secret show TEST_ALPHA -p $P)" == *'comment with'* ]] && ok "json round-trip comment" || bad "json round-trip comment"

# --- export env / import into another project ---
secret export -p $P --format env -o "$TD/x.env" >/dev/null 2>&1 && ok "export env" || bad "export env"
secret import "$TD/x.env" -p $P2 >/dev/null 2>&1 && ok "import env -> other project" || bad "import env -> other project"
[[ "$(secret get TEST_ALPHA -p $P2)" == "$V1" ]] && ok "env round-trip special chars" || bad "env round-trip special chars"

# --- age round trip (recipient/identity so it runs non-interactively) ---
age-keygen -o "$TD/key.txt" >/dev/null 2>&1
rec=$(awk '/public key/ {print $NF}' "$TD/key.txt")
SECRET_AGE_ARGS="-r $rec" secret export -p $P -o "$TD/x.json.age" >/dev/null 2>&1 \
  && ok "export age" || bad "export age"
[[ "$(head -c 21 "$TD/x.json.age" 2>/dev/null)" == 'age-encryption.org/v1' ]] \
  && ok "age file is encrypted" || bad "age file is encrypted"
SECRET_AGE_DECRYPT_ARGS="-i $TD/key.txt" secret import "$TD/x.json.age" -p $P3 >/dev/null 2>&1 \
  && ok "import age" || bad "import age"
[[ "$(secret get TEST_ALPHA -p $P3)" == "$V1" ]] && ok "age round-trip value" || bad "age round-trip value"

# --- format inference from -o suffix ---
secret export -p $P -o "$TD/infer.env" >/dev/null 2>&1
grep -q 'export TEST_ALPHA=' "$TD/infer.env" 2>/dev/null \
  && ok "format inferred from .env suffix" || bad "format inferred from .env suffix"

# --- update ---
print -r -- 'rotated-789' | secret update TEST_ALPHA -p $P --stdin >/dev/null \
  && ok "update value via stdin" || bad "update value via stdin"
[[ "$(secret get TEST_ALPHA -p $P)" == 'rotated-789' ]] \
  && ok "updated value readable" || bad "updated value readable"
upshow=$(secret show TEST_ALPHA -p $P)
[[ $upshow == *'comment with "quotes" and spaces'* ]] \
  && ok "value update keeps comment" || bad "value update keeps comment"
[[ $upshow =~ 'Kind:[[:space:]]+api key' ]] \
  && ok "value update keeps kind" || bad "value update keeps kind"

secret update TEST_ALPHA -p $P -j 'fresh comment' >/dev/null \
  && ok "update comment only" || bad "update comment only"
[[ "$(secret get TEST_ALPHA -p $P)" == 'rotated-789' ]] \
  && ok "comment update keeps value" || bad "comment update keeps value"
upshow=$(secret show TEST_ALPHA -p $P)
[[ $upshow == *'fresh comment'* ]] && ok "comment updated" || bad "comment updated"
[[ $upshow =~ 'Kind:[[:space:]]+api key' ]] \
  && ok "comment update keeps kind" || bad "comment update keeps kind"

secret update TEST_ALPHA -p $P -D 'token' >/dev/null \
  && ok "update kind only" || bad "update kind only"
upshow=$(secret show TEST_ALPHA -p $P)
[[ $upshow =~ 'Kind:[[:space:]]+token' ]] && ok "kind updated" || bad "kind updated"
[[ $upshow == *'fresh comment'* ]] && ok "kind update keeps comment" || bad "kind update keeps comment"
[[ "$(secret get TEST_ALPHA -p $P)" == 'rotated-789' ]] \
  && ok "kind update keeps value" || bad "kind update keeps value"

secret update TEST_ALPHA -p $P -j '' >/dev/null \
  && ok "update clears comment with -j ''" || bad "update clears comment with -j ''"
[[ "$(secret show TEST_ALPHA -p $P)" != *'fresh comment'* ]] \
  && ok "comment cleared" || bad "comment cleared"

secret update TEST_ALPHA -p $P >/dev/null 2>&1 \
  && bad "update with no flags fails" || ok "update with no flags fails"
secret update TEST_NOPE -p $P -j 'x' >/dev/null 2>&1 \
  && bad "update of missing item fails" || ok "update of missing item fails"
print -r -- 'y' | secret update TEST_NOPE -p $P --stdin >/dev/null 2>&1 \
  && bad "update --stdin of missing item fails" || ok "update --stdin of missing item fails"

# --- keychain auto-mapping ---
security create-keychain -p testpass "$KCP" 2>/dev/null \
  && ok "fixture: create custom keychain" || bad "fixture: create custom keychain"
security unlock-keychain -p testpass "$KCP" 2>/dev/null
# register in the user search list (auto-mapping requires it)
slarr=(${(f)"$(security list-keychains -d user | sed -E 's/^[[:space:]]*\"(.*)\"[[:space:]]*$/\1/')"})
security list-keychains -d user -s "${slarr[@]}" "$KCP" \
  && ok "fixture: add to search list" || bad "fixture: add to search list"

print -r -- 'kc-value-1' | secret set KC_ONE -p $KCN --stdin >/dev/null 2>&1 \
  && ok "set into auto-mapped keychain" || bad "set into auto-mapped keychain"
security find-generic-password -s "secret.$KCN" -a KC_ONE "$KCP" >/dev/null 2>&1 \
  && ok "item lives in custom keychain" || bad "item lives in custom keychain"
security find-generic-password -s "secret.$KCN" -a KC_ONE "$BKC" >/dev/null 2>&1 \
  && bad "item absent from base keychain" || ok "item absent from base keychain"
[[ "$(secret get KC_ONE -p $KCN)" == 'kc-value-1' ]] \
  && ok "get via auto-mapping" || bad "get via auto-mapping"
[[ "$(secret show KC_ONE -p $KCN)" == *"$KCN.keychain-db"* ]] \
  && ok "show reports mapped keychain" || bad "show reports mapped keychain"
[[ "$(secret show KC_ONE -p $KCN | awk '/^Label:/ {print $2}')" == "KC_ONE" ]] \
  && ok "label unprefixed in own keychain" || bad "label unprefixed in own keychain"
setmsg=$(print -r -- 'v3' | secret set KC_THREE -p $KCN --stdin 2>/dev/null)
[[ $setmsg == *"[keychain: $KCN]"* ]] \
  && ok "stored message shows kc label" || bad "stored message shows kc label"
projarr3=(${(f)"$(secret projects)"})
(( ${projarr3[(Ie)$KCN]} )) \
  && ok "projects includes custom keychain" || bad "projects includes custom keychain"

# --- unlisted keychain file must NOT auto-map (metadata protection) ---
security create-keychain -p testpass "$KCP2" 2>/dev/null
projarr4=(${(f)"$(secret projects)"})
if (( ${projarr4[(Ie)$KCN2]} )); then
  bad "projects omits unlisted keychain name"
else
  ok "projects omits unlisted keychain name"
fi
print -r -- 'unlisted-v' | secret set KC_UL -p $KCN2 --stdin >/dev/null 2>&1
security find-generic-password -s "secret.$KCN2" -a KC_UL "$KCP2" >/dev/null 2>&1 \
  && bad "unlisted keychain not auto-mapped" || ok "unlisted keychain not auto-mapped"
security find-generic-password -s "secret.$KCN2" -a KC_UL "$BKC" >/dev/null 2>&1 \
  && ok "unlisted project stored in base keychain" || bad "unlisted project stored in base keychain"
secret rm KC_UL -p $KCN2 -f >/dev/null 2>&1
secret keychain register $KCN2 >/dev/null 2>&1 && ok "keychain register" || bad "keychain register"
regsl=(${(f)"$(security list-keychains -d user | sed -E 's/^[[:space:]]*"(.*)"[[:space:]]*$/\1/')"})
(( ${regsl[(Ie)$KCP2]} )) && ok "register adds to search list" || bad "register adds to search list"
security delete-keychain "$KCP2" >/dev/null 2>&1

# --- -k default bypasses the mapping ---
print -r -- 'kc-value-2' | secret -k default set KC_TWO -p $KCN --stdin >/dev/null 2>&1
security find-generic-password -s "secret.$KCN" -a KC_TWO "$KCP" >/dev/null 2>&1 \
  && bad "-k default bypasses mapping" || ok "-k default bypasses mapping"
security find-generic-password -s "secret.$KCN" -a KC_TWO "$DKC" >/dev/null 2>&1 \
  && ok "-k default stored in default keychain" || bad "-k default stored in default keychain"
[[ "$(secret -k default get KC_TWO -p $KCN)" == 'kc-value-2' ]] \
  && ok "-k default get" || bad "-k default get"

# --- keychain remember / auto-unlock ---
print -r -- 'testpass' | secret keychain remember $KCN --stdin >/dev/null 2>&1 \
  && ok "keychain remember --stdin" || bad "keychain remember --stdin"
security find-generic-password -s 'keychain-password' -a $KCN -w "$DKC" >/dev/null 2>&1 \
  && ok "unlock password stored in login" || bad "unlock password stored in login"
print -r -- 'wrongpass' | secret keychain remember $KCN --stdin >/dev/null 2>&1 \
  && bad "remember rejects wrong password" || ok "remember rejects wrong password"
security unlock-keychain -p testpass "$KCP" 2>/dev/null   # restore after wrong-pw lock
secret keychain lock $KCN >/dev/null 2>&1
[[ "$(secret get KC_ONE -p $KCN)" == 'kc-value-1' ]] \
  && ok "auto-unlock on access after lock" || bad "auto-unlock on access after lock"
lockedls=$(secret keychain lock $KCN >/dev/null 2>&1; secret ls -p $KCN)
[[ $lockedls == *KC_ONE* ]] \
  && ok "auto-unlock covers ls/dump" || bad "auto-unlock covers ls/dump"
secret keychain forget $KCN >/dev/null 2>&1 && ok "keychain forget" || bad "keychain forget"
security find-generic-password -s 'keychain-password' -a $KCN "$DKC" >/dev/null 2>&1 \
  && bad "forget removed login item" || ok "forget removed login item"
security unlock-keychain -p testpass "$KCP" 2>/dev/null   # unlocked for remaining tests

# --- master password (isolated via test hooks) ---
export SECRET_MASTER_ACCOUNT=master-selftest
export SECRET_TEST_ONLY_KC='secret-selftest*'
MP='master-pass-one'
MP2='master-pass-two'
KCN3=secret-selftest-mkc
KCP3=$HOME/Library/Keychains/$KCN3.keychain-db

print -r -- 'testpass' | secret keychain remember $KCN --stdin >/dev/null 2>&1
msetout=$(print -r -- "$MP" | secret keychain master set --stdin 2>&1) \
  && ok "master set --stdin" || bad "master set --stdin"
[[ $msetout == *adopted:*$KCN* ]] \
  && ok "master set adopts via stored item" || bad "master set adopts via stored item"
[[ "$(secret keychain master reveal)" == "$MP" ]] && ok "master reveal" || bad "master reveal"
security find-generic-password -s 'keychain-password' -a $KCN "$DKC" >/dev/null 2>&1 \
  && bad "adoption removes individual item" || ok "adoption removes individual item"
[[ "$(secret keychain master status)" == *'master: stored'* ]] \
  && ok "master status shows stored" || bad "master status shows stored"

secret keychain lock $KCN >/dev/null 2>&1
[[ "$(secret get KC_ONE -p $KCN)" == 'kc-value-1' ]] \
  && ok "auto-unlock via master fallback" || bad "auto-unlock via master fallback"

secret keychain create $KCN3 --no-autolock >/dev/null 2>&1 \
  && ok "headless create via master" || bad "headless create via master"
[[ -e $KCP3 ]] && ok "created keychain file exists" || bad "created keychain file exists"
print -r -- 'mkc-v' | secret set MK_ONE -p $KCN3 --stdin >/dev/null 2>&1
[[ "$(secret get MK_ONE -p $KCN3)" == 'mkc-v' ]] \
  && ok "master-created keychain usable" || bad "master-created keychain usable"

print -r -- "$MP2" | secret keychain master rotate --stdin >/dev/null 2>&1 \
  && ok "master rotate --stdin" || bad "master rotate --stdin"
[[ "$(secret keychain master reveal)" == "$MP2" ]] \
  && ok "reveal shows rotated value" || bad "reveal shows rotated value"
secret keychain lock $KCN >/dev/null 2>&1
[[ "$(secret get KC_ONE -p $KCN)" == 'kc-value-1' ]] \
  && ok "unlock works after rotate" || bad "unlock works after rotate"
security lock-keychain "$KCP" 2>/dev/null
print -r -- "unlock-keychain -p \"$MP\" \"$KCP\"" | security -i >/dev/null 2>&1 \
  && bad "old master password rejected" || ok "old master password rejected"
print -r -- "unlock-keychain -p \"$MP2\" \"$KCP\"" | security -i >/dev/null 2>&1

secret keychain master forget >/dev/null 2>&1 && ok "master forget" || bad "master forget"
secret keychain master reveal >/dev/null 2>&1 \
  && bad "reveal fails after forget" || ok "reveal fails after forget"

# restore fixture to testpass for the remaining legacy tests
print -r -- "set-keychain-password -o \"$MP2\" -p \"testpass\" \"$KCP\"" | security -i >/dev/null 2>&1
security unlock-keychain -p testpass "$KCP" 2>/dev/null
secret keychain rm $KCN3 -f >/dev/null 2>&1
security delete-generic-password -s 'keychain-password' -a master-selftest >/dev/null 2>&1
unset SECRET_MASTER_ACCOUNT SECRET_TEST_ONLY_KC

# --- keychain subcommands ---
kcls=$(secret keychain ls)
[[ $kcls == *$KCN* ]] && ok "keychain ls lists custom" || bad "keychain ls lists custom"
[[ $kcls == *'(default)'* ]] && ok "keychain ls marks default" || bad "keychain ls marks default"
[[ "$(secret keychain info $KCN 2>&1)" == *"$KCP"* ]] \
  && ok "keychain info shows path" || bad "keychain info shows path"
secret keychain lock $KCN >/dev/null 2>&1 && ok "keychain lock" || bad "keychain lock"
security unlock-keychain -p testpass "$KCP" 2>/dev/null
[[ "$(secret get KC_ONE -p $KCN)" == 'kc-value-1' ]] \
  && ok "readable after raw unlock" || bad "readable after raw unlock"
secret keychain rm $KCN -f >/dev/null 2>&1 && ok "keychain rm" || bad "keychain rm"
[[ ! -e $KCP ]] && ok "keychain file removed" || bad "keychain file removed"
secret keychain rm $KCN -f >/dev/null 2>&1 \
  && bad "keychain rm of missing fails" || ok "keychain rm of missing fails"

print ''
if (( fails == 0 )); then
  print -r -- "ALL TESTS PASSED"
else
  print -r -- "$fails TEST(S) FAILED"
fi
exit $fails
