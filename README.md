<p align="center">
  <img src="assets/icon.svg" width="96" alt="workstation icon">
</p>

<h1 align="center">workstation</h1>

<p align="center">
  <img src="https://github.com/ChandlerTayek/workstation/actions/workflows/lint.yml/badge.svg" alt="lint">
</p>

My development environment for platform engineering on Ubuntu (WSL): shell configuration, pinned CLI tools, and VS Code setup, installable on a new machine with one command. 🚀

## 📦 What's included

**🐚 Shell (`bash/`)**: a stock Ubuntu `.bashrc` that loads small topic files from `~/.bashrc.d/`:

| File | Highlights |
|---|---|
| `00-tools.sh` | fzf (Ctrl+R fuzzy history), direnv, mise |
| `aws.sh` | Profile picker, SSO login, color-coded prompt (red for prod), ECR login, SSO expiry check |
| `k8s.sh` | `k` alias, completions, EKS kubeconfig helper, context and namespace pickers |
| `terraform.sh` | Shared provider cache, `tfcheck` (fmt, validate, tflint), `tfp`/`tfa` with a prod apply guard |
| `git.sh` | Short aliases, branch picker, merged-branch cleanup, GitHub Actions watcher |
| `jira.sh` | Atlassian CLI token expiry reminder and guided renewal |

**🧰 Tools (`mise/config.toml`)**: kubectl, helm, flux, terraform, tflint, shellcheck, and hadolint, pinned globally and switchable per project.

**🧩 VS Code (`vscode/`)**: extension lists for the WSL and Windows sides, plus reference settings.

## ⚡ Install

```bash
git clone https://github.com/ChandlerTayek/workstation.git ~/projects/workstation
cd ~/projects/workstation
./install.sh
```

The installer links the config files into your home folder, installs apt packages (direnv, gh, trivy, acli), the AWS CLI, mise and its tools, fzf, and the WSL side VS Code extensions. It also adds mise's shims to your `PATH` in `~/.profile`, so editors and other background programs can find the mise tools. It's safe to re-run: tools already present are skipped and correct links are left alone. Don't move the repo after installing, since the symlinks point to its path.

> 🛟 **Existing files are backed up, not deleted.** If a file like `~/.bashrc` already exists, it's renamed to `~/.bashrc.bak.<timestamp>` before the link is created. At the end, the installer lists every backup and asks whether to delete them. The default is no, so compare them first with `diff` if you're unsure.

## ✅ After installing

1. Fill in `~/.bashrc.local` (created from `bash/bashrc.local.example`). This holds anything machine or company specific, like your SSO session name and Jira site, and is never committed.
2. Create AWS profiles with `aws configure sso`.
3. Run `source ~/.bashrc`, or open a new terminal.
4. On Windows, install the extensions listed in `vscode/extensions-windows.txt`.

## 🔗 How it works

The real files live in this repo, and your home folder holds symlinks to them. Editing `~/.bashrc.d/aws.sh` edits the copy here, so `git diff` shows every change and `git commit` saves it.

🔒 Kept out of the repo on purpose: `~/.bashrc.local`, `~/.aws/`, `~/.kube/`, and any `.envrc` files. Those contain account names, profiles, and cluster details that belong to a specific machine or employer.

## 🛠️ Commands

All commands that take an optional name open an fzf picker when you leave the name off.

### ☁️ AWS (`aws.sh`)

| Command | Does |
|---|---|
| `awsl` | Log in to AWS SSO using the session in `AWS_SSO_SESSION` |
| `awsp [profile]` | Switch the active AWS profile; tab completes profile names |
| `awsr <region>` | Switch the active region |
| `awsx` | Clear the active profile and any exported credentials |
| `awswho` | Show which account and role you're currently using |
| `ecrlogin` | Log Docker into ECR for the current account and region |

### ☸️ Kubernetes (`k8s.sh`)

| Command | Does |
|---|---|
| `k` | Short for `kubectl`, with tab completion |
| `ekscfg <cluster>` | Add an EKS cluster to kubeconfig, named `<profile>-<cluster>` |
| `kctx [context]` | Switch kube context |
| `kns [namespace]` | Switch the default namespace for the current context |
| `kgp` | `kubectl get pods` |
| `kl <pod>` | Follow a pod's logs (`kubectl logs -f`) |

### 🏗️ Terraform (`terraform.sh`)

| Command | Does |
|---|---|
| `tf` | Short for `terraform` |
| `tfcheck` | Format, validate, and lint (tflint) the current directory |
| `tfp [args]` | Plan to a saved `tfplan` file |
| `tfa` | Apply the saved plan; asks you to type `prod` when a prod profile is active 🚨 |

### 🌿 Git and GitHub (`git.sh`)

| Command | Does |
|---|---|
| `gs` | Short status with branch info |
| `gl` | Compact graph of the last 20 commits |
| `gd` | `git diff` |
| `gco [branch]` | Switch branches |
| `gclean` | Delete local branches already merged into the default branch 🧹 |
| `ghw` | Watch the latest GitHub Actions run for the current branch 👀 |

### 🎫 Jira (`jira.sh`)

| Command | Does |
|---|---|
| `jirarenew` | Walk through creating and saving a new Atlassian CLI token |

### ⌨️ Keyboard shortcuts (fzf)

| Keys | Does |
|---|---|
| Ctrl+R | Fuzzy search your shell history |
| Ctrl+T | Insert a file path into the current command |
| Alt+C | Jump into a subfolder |

## 🤖 Automatic behavior

These need no command:

- 🎨 **Prompt shows the active AWS profile**, yellow normally and red when the name contains `prod`.
- 🔑 **SSO check at startup** warns when your AWS session has expired. It makes at most one quick network call per hour.
- ⏰ **Jira token reminder** warns at startup once the token is within 7 days of expiring.
- 📂 **direnv** loads a folder's `.envrc` when you `cd` into it and unloads it when you leave, which makes it easy to set `AWS_PROFILE` per project.
- 🔀 **mise** switches tool versions per project based on that project's `mise.toml`.
- 💾 **Terraform provider cache** downloads each provider once and reuses it across every project.

## ⚙️ Local settings

`~/.bashrc.local` holds the values that differ per machine or employer:

| Variable | Used by |
|---|---|
| `AWS_SSO_SESSION` | `awsl`, the `sso-session` name from `~/.aws/config` |
| `AWS_SSO_CHECK_PROFILE` | The startup SSO check; any profile that uses that session |
| `ACLI_SITE` | `jirarenew`, your site such as `yoursite.atlassian.net` |
| `ACLI_EMAIL` | `jirarenew`, your Atlassian login email |

## 📄 License

MIT
