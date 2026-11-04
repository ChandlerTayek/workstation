# shellcheck shell=bash
if command -v kubectl >/dev/null; then
  # shellcheck source=/dev/null
  source <(kubectl completion bash)
  alias k=kubectl
  complete -o default -F __start_kubectl k
fi
# shellcheck source=/dev/null
command -v helm >/dev/null && source <(helm completion bash)

# Add an EKS cluster to kubeconfig with a readable name, using the current profile
ekscfg() {
  [ -z "$1" ] && { echo "usage: ekscfg <cluster-name>"; return 1; }
  [ -z "$AWS_PROFILE" ] && { echo "Set AWS_PROFILE first (awsp)"; return 1; }
  aws eks update-kubeconfig --name "$1" --alias "${AWS_PROFILE}-$1" --profile "$AWS_PROFILE"
}

# Switch kube context with a fuzzy picker
kctx() {
  local c="${1:-$(kubectl config get-contexts -o name | fzf --prompt='kube context> ')}"
  [ -n "$c" ] && kubectl config use-context "$c"
}

# Switch the default namespace for the current context
kns() {
  local n="${1:-$(kubectl get ns -o name | cut -d/ -f2 | fzf --prompt='namespace> ')}"
  [ -n "$n" ] && kubectl config set-context --current --namespace="$n"
}

alias kgp='kubectl get pods'
alias kl='kubectl logs -f'