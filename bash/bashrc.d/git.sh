# shellcheck shell=bash
# Git and GitHub CLI shortcuts

alias gs='git status -sb'  # Show short git status with branch info
alias gl='git log --oneline --graph --decorate -20'  # Show a compact graph of the last 20 commits
alias gd='git diff'   # Show unstaged changes

gco() {  # Switch branch: gco <branch>, or pick with fzf
  local b="${1:-$(git branch --format='%(refname:short)' | fzf --prompt='branch> ')}"
  [ -n "$b" ] && git switch "$b"
}

gclean() {  # Delete local branches already merged
  local def
  def=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | cut -d/ -f2)
  def=${def:-main}
  git fetch --prune
  git branch --merged "$def" | grep -vE "^\*|^\s*$def$" | xargs -r git branch -d
}

ghw() {  # Watch the latest Actions run for this branch
  local id
  id=$(gh run list --branch "$(git branch --show-current)" --limit 1 --json databaseId -q '.[0].databaseId')
  if [ -n "$id" ]; then gh run watch "$id"; else echo "No runs found for this branch"; fi
}