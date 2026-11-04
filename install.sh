#!/usr/bin/env bash
# Set up this dev environment on a fresh Ubuntu/WSL machine.
# Safe to re-run: existing files are backed up, installed tools are skipped.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUPS=()
have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '\n==> %s\n' "$*"; }

# Symlink $1 (in repo) to $2 (in home), backing up anything already there
link() {
  local src="$DOTFILES/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok      $dest"; return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak.$STAMP"
    BACKUPS+=("$dest.bak.$STAMP")
    echo "backup  $dest -> $dest.bak.$STAMP"
  fi
  ln -s "$src" "$dest"
  echo "linked  $dest"
}

# Add a signed apt repository: name, key URL, repo line
add_apt_repo() {
  [ -f "/etc/apt/sources.list.d/$1.list" ] && return
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -nv -O- "$2" | sudo gpg --dearmor -o "/etc/apt/keyrings/$1.gpg"
  sudo chmod go+r "/etc/apt/keyrings/$1.gpg"
  echo "deb [signed-by=/etc/apt/keyrings/$1.gpg] $3" | sudo tee "/etc/apt/sources.list.d/$1.list" >/dev/null
}

log "Linking config files"
link bash/bashrc      "$HOME/.bashrc"
link bash/bashrc.d    "$HOME/.bashrc.d"
link mise/config.toml "$HOME/.config/mise/config.toml"
if [ ! -f "$HOME/.bashrc.local" ]; then
  cp "$DOTFILES/bash/bashrc.local.example" "$HOME/.bashrc.local"
  echo "created ~/.bashrc.local (fill in your values)"
fi

log "Installing apt packages and repos"
sudo apt-get update -qq
sudo apt-get install -y -qq git curl wget unzip gnupg direnv gh
add_apt_repo trivy https://aquasecurity.github.io/trivy-repo/deb/public.key \
  "https://aquasecurity.github.io/trivy-repo/deb generic main"
add_apt_repo acli https://acli.atlassian.com/gpg/public-key.asc \
  "https://acli.atlassian.com/linux/deb stable main"
sudo apt-get update -qq
sudo apt-get install -y -qq trivy acli

if ! have aws; then
  log "Installing AWS CLI v2"
  curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
  unzip -qo /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install
fi

if [ ! -x "$HOME/.local/bin/mise" ]; then
  log "Installing mise"
  curl -fsSL https://mise.run | sh
fi
log "Installing mise tools from mise/config.toml"
"$HOME/.local/bin/mise" install

# Let editors and other non-interactive programs find mise tools
# shellcheck disable=SC2016  # literal $HOME/$PATH are meant to expand at login, not now
grep -q 'mise/shims' "$HOME/.profile" 2>/dev/null \
  || echo 'export PATH="$HOME/.local/share/mise/shims:$PATH"' >> "$HOME/.profile"
  
if [ ! -d "$HOME/.fzf" ]; then
  log "Installing fzf"
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --key-bindings --completion --no-update-rc
fi

if have code; then
  log "Installing VS Code extensions (WSL side)"
    grep -v '^\s*#' "$DOTFILES/vscode/extensions-wsl.txt" | xargs -r -n1 code --install-extension \
    || echo "Some extensions failed to install; see the messages above."
fi

if [ -d "$HOME/.vscode-server" ]; then
  log "Applying VS Code remote (WSL) settings"
  link vscode/settings-wsl.json "$HOME/.vscode-server/data/Machine/settings.json"
fi

if [ ${#BACKUPS[@]} -gt 0 ]; then
  log "Backups created"
  echo "These existing files were moved aside before linking:"
  printf '  %s\n' "${BACKUPS[@]}"
  echo
  echo "Compare one with the new version, for example:"
  echo "  diff -r ${BACKUPS[0]} ${BACKUPS[0]%.bak.*}"
  if [ -t 0 ]; then
    read -rp "Delete these backups now? [y/N] " ans
    if [[ $ans =~ ^[Yy]$ ]]; then
      rm -rf "${BACKUPS[@]}"
      echo "Backups deleted."
    else
      echo "Kept. Delete them later with: rm -rf ${BACKUPS[*]}"
    fi
  fi
fi

log "Done. Next steps:"
cat <<'EOF'
  1. Edit ~/.bashrc.local with your SSO session, Jira site/email, and check profile
  2. Run: aws configure sso      (create your profiles)
  3. Run: source ~/.bashrc
  4. On Windows, install VS Code extensions from vscode/extensions-windows.txt
EOF
