# shellcheck shell=bash
# Jira (acli) token expiry reminder and renewal helper

ACLI_TOKEN_EXPIRY_FILE="$HOME/.config/dotfiles/acli-token-expiry"

__acli_token_check() {
  [ -r "$ACLI_TOKEN_EXPIRY_FILE" ] || return
  local exp days
  exp=$(cat "$ACLI_TOKEN_EXPIRY_FILE")
  days=$(( ( $(date -d "$exp" +%s) - $(date +%s) ) / 86400 ))
  if [ "$days" -lt 0 ]; then
    echo "Jira token expired on $exp (run jirarenew)"
  elif [ "$days" -le 7 ]; then
    echo "Jira token expires in $days day(s) on $exp (run jirarenew)"
  fi
}
__acli_token_check

jirarenew() {  # Create and save a new Atlassian CLI token
  : "${ACLI_SITE:?Set ACLI_SITE in ~/.bashrc.local}"
  : "${ACLI_EMAIL:?Set ACLI_EMAIL in ~/.bashrc.local}"
  local token days
  echo "1. Create a token: https://id.atlassian.com/manage-profile/security/api-tokens"
  read -rp "2. Expiry you chose, in days [90]: " days
  days=${days:-90}
  read -rsp "3. Paste the token (hidden): " token; echo
  if echo "$token" | acli jira auth login --site "$ACLI_SITE" --email "$ACLI_EMAIL" --token; then
    mkdir -p "$(dirname "$ACLI_TOKEN_EXPIRY_FILE")"
    date -d "+$days days" +%F > "$ACLI_TOKEN_EXPIRY_FILE"
    echo "Saved. Token expires $(cat "$ACLI_TOKEN_EXPIRY_FILE")."
  fi
  unset token
}