# shellcheck shell=bash
if command -v kubectl >/dev/null; then
  # shellcheck source=/dev/null
  source <(kubectl completion bash)
  alias k=kubectl  # Short for kubectl
  complete -o default -F __start_kubectl k
fi
# shellcheck source=/dev/null
command -v helm >/dev/null && source <(helm completion bash)

ekscfg() {  # Add an EKS cluster to kubeconfig: ekscfg <cluster>
  [ -z "$1" ] && { echo "usage: ekscfg <cluster-name>"; return 1; }
  [ -z "$AWS_PROFILE" ] && { echo "Set AWS_PROFILE first (awsp)"; return 1; }
  aws eks update-kubeconfig --name "$1" --alias "${AWS_PROFILE}-$1" --profile "$AWS_PROFILE"
}

kctx() {  # Switch kube context: kctx <name>, or pick with fzf
  local c="${1:-$(kubectl config get-contexts -o name | fzf --prompt='kube context> ')}"
  [ -n "$c" ] && kubectl config use-context "$c"
}

kns() {  # Switch namespace: kns <name>, or pick with fzf
  local n="${1:-$(kubectl get ns -o name | cut -d/ -f2 | fzf --prompt='namespace> ')}"
  [ -n "$n" ] && kubectl config set-context --current --namespace="$n"
}

alias kgp='kubectl get pods'  # List pods in the current namespace
alias kl='kubectl logs -f'  # Follow a pod's logs: kl <pod>