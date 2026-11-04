# shellcheck shell=bash
# mycmds: list my custom commands and aliases, grouped by file

mycmds() {  # List my custom commands with descriptions
  local f
  for f in ~/.bashrc.d/*.sh ~/.bashrc.local; do
    [ -r "$f" ] || continue
    awk -v file="$(basename "$f")" '
      # Remember a comment line (but not shellcheck directives) for the next line
      /^[[:space:]]*#/ {
        c = $0; sub(/^[[:space:]]*#[[:space:]]*/, "", c)
        if (c ~ /^shellcheck/) c = ""
        next
      }
      match($0, /^[[:space:]]*(alias[[:space:]]+[A-Za-z0-9_-]+|[A-Za-z0-9_-]+\(\))/) {
        n = substr($0, RSTART, RLENGTH)
        sub(/^[[:space:]]*/, "", n); sub(/^alias[[:space:]]+/, "", n); sub(/\(\)$/, "", n)
        d = c
        if (match($0, /[[:space:]]#[[:space:]]/)) d = substr($0, RSTART + 3)   # trailing comment wins
        if (n !~ /^_/) printf "%-14s %-11s %s\n", file, n, d
      }
      { c = "" }
    ' "$f"
  done
}