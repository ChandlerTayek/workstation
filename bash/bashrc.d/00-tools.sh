# shellcheck shell=bash

# fzf: Ctrl+R fuzzy history, Ctrl+T file picker, Alt+C cd into folder
# shellcheck source=/dev/null
[ -f ~/.fzf.bash ] && . ~/.fzf.bash

# direnv: auto-load .envrc when you cd into a folder
command -v direnv >/dev/null && eval "$(direnv hook bash)"

# mise: auto-switch tool versions per project
[ -x ~/.local/bin/mise ] && eval "$(~/.local/bin/mise activate bash)"