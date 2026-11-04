# shellcheck shell=bash
# Prompt shows the active profile: red for prod, yellow otherwise
__aws_ps1() {
  [ -z "$AWS_PROFILE" ] && return
  if [[ $AWS_PROFILE == *prod* ]]; then
    printf '\001\033[01;31m\002[aws:%s]\001\033[00m\002 ' "$AWS_PROFILE"
  else
    printf '\001\033[01;33m\002[aws:%s]\001\033[00m\002 ' "$AWS_PROFILE"
  fi
}
case "$PS1" in
  *__aws_ps1*) ;;  # already added, don't stack it
  *) PS1='$(__aws_ps1)'"$PS1" ;;
esac

awsl() { aws sso login --sso-session "${AWS_SSO_SESSION:?Set AWS_SSO_SESSION in ~/.bashrc.local}"; }  # Log in to AWS SSO (once a day)
awsp() {  # Switch AWS profile: awsp <name>, or pick with fzf
  local p="${1:-$(aws configure list-profiles | fzf --prompt='aws profile> ')}"
  [ -n "$p" ] && export AWS_PROFILE="$p"
}
awsx() { unset AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; }  # Clear the active AWS profile and credentials
awswho() { aws sts get-caller-identity; }  # Show the current AWS account and role
awsr() { export AWS_REGION="$1"; }  # Switch AWS region: awsr <region>

ecrlogin() {  # Log Docker into ECR for the current account
  local acct region
  acct=$(aws sts get-caller-identity --query Account --output text) || return
  region=${AWS_REGION:-$(aws configure get region)}
  aws ecr get-login-password --region "$region" \
    | docker login --username AWS --password-stdin "$acct.dkr.ecr.$region.amazonaws.com"
}


# Warn at shell start if the SSO session is missing or expired
__aws_sso_check() {
  local c f="" exp
  for c in ~/.aws/sso/cache/*.json; do
    [ -f "$c" ] || continue
    grep -q '"accessToken"' "$c" || continue
    if [ -z "$f" ] || [ "$c" -nt "$f" ]; then f="$c"; fi
  done
  if [ -z "$f" ]; then
    echo "AWS SSO: not logged in (run awsl)"
    return
  fi
  exp=$(grep -o '"expiresAt": *"[^"]*"' "$f" | cut -d'"' -f4)
  [ "$(date -u +%s)" -lt "$(date -u -d "$exp" +%s)" ] && return

  # Access token is past its 1-hour life; the CLI may still refresh it.
  # Skip the network check if one succeeded within the last hour
  local stamp="$HOME/.cache/aws-sso-check-ok"
  [ -n "$(find "$stamp" -mmin -60 2>/dev/null)" ] && return

  if grep -q '"refreshToken"' "$f" && [ -n "$AWS_SSO_CHECK_PROFILE" ]; then
    if timeout 5 aws sts get-caller-identity --profile "$AWS_SSO_CHECK_PROFILE" >/dev/null 2>&1; then
      mkdir -p "$HOME/.cache" && touch "$stamp"
      return
    fi
  fi
  echo "AWS SSO: session expired (run awsl)"
}
__aws_sso_check

# Tab completion for awsp from your config file
[ -f ~/.aws/config ] && complete -W "$(grep -o '^\[profile [^]]*' ~/.aws/config | cut -d' ' -f2)" awsp

# AWS CLI tab completion
command -v aws_completer >/dev/null && complete -C "$(command -v aws_completer)" aws