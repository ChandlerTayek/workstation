# shellcheck shell=bash
# Git and GitHub CLI shortcuts

alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'

# Fuzzy-pick a local branch to switch to
gco() {
  local b="${1:-$(git branch --format='%(refname:short)' | fzf --prompt='branch> ')}"
  [ -n "$b" ] && git switch "$b"
}

# Delete local branches already merged into the default branch
gclean() {
  local def
  def=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | cut -d/ -f2)
  def=${def:-main}
  git fetch --prune
  git branch --merged "$def" | grep -vE "^\*|^\s*$def$" | xargs -r git branch -d
}

# Watch the latest GitHub Actions run on the current branch
ghw() {
  local id
  id=$(gh run list --branch "$(git branch --show-current)" --limit 1 --json databaseId -q '.[0].databaseId')
  if [ -n "$id" ]; then gh run watch "$id"; else echo "No runs found for this branch"; fi
}