# shellcheck shell=bash
# Terraform shortcuts, shared provider cache, and a prod apply guard

alias tf=terraform

# Download each provider once and reuse it across every project and account
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

# Format, validate, and lint the current directory
tfcheck() {
  terraform fmt -recursive || return
  terraform validate || return
  if command -v tflint >/dev/null; then
    tflint --init >/dev/null && tflint
  fi
}

# Plan to a saved file so apply runs exactly what you reviewed
tfp() { terraform plan -out=tfplan "$@"; }

# Apply the saved plan; requires typing 'prod' when a prod profile is active
tfa() {
  if [[ $AWS_PROFILE == *prod* ]]; then
    local ans
    read -rp "Applying to PROD ($AWS_PROFILE). Type 'prod' to continue: " ans
    [ "$ans" = "prod" ] || { echo "Aborted."; return 1; }
  fi
  terraform apply tfplan
}