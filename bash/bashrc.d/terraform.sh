# shellcheck shell=bash
# Terraform shortcuts, shared provider cache, and a prod apply guard

alias tf=terraform  # Short for terraform

# Download each provider once and reuse it across every project and account
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

tfcheck() {  # Format, validate, and lint this directory
  terraform fmt -recursive || return
  terraform validate || return
  if command -v tflint >/dev/null; then
    tflint --init >/dev/null && tflint
  fi
}

tfp() { terraform plan -out=tfplan "$@"; }  # Plan to a tfplan file for review

tfa() {  # Apply tfplan (asks to confirm on prod)
  if [[ $AWS_PROFILE == *prod* ]]; then
    local ans
    read -rp "Applying to PROD ($AWS_PROFILE). Type 'prod' to continue: " ans
    [ "$ans" = "prod" ] || { echo "Aborted."; return 1; }
  fi
  terraform apply tfplan
}