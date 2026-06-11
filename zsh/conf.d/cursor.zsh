# Force vertical bar (|) cursor on every prompt.
# Recovers cursor shape after TUIs (nvim, less, etc.) reset it.
# DECSCUSR sequences:
#   1/2 = block (blink/steady)
#   3/4 = underline (blink/steady)
#   5/6 = bar (blink/steady)
function _cursor_bar() {
  print -n '\e[6 q'
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _cursor_bar
add-zsh-hook preexec _cursor_bar
