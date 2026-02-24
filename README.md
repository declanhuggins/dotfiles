# dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/) and [Ansible](https://www.ansible.com/).

Supports **macOS**, **Ubuntu**, and **Arch Linux**.

## Quick Start

On a new machine, run:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply declanhuggins/dotfiles
```

If chezmoi isn't in your `$PATH` after install (common on Linux where it defaults to `~/bin`):

```bash
export PATH="$HOME/bin:$PATH"
~/bin/chezmoi init --apply declanhuggins/dotfiles
```

This will:
1. Install chezmoi
2. Clone this repo
3. Install Ansible and run the playbook (installs zsh, git, nano, fastfetch, curl, wget)
4. Set zsh as the default shell
5. Pull Oh My Zsh
6. Apply all config files with OS-appropriate settings

## What's Managed

| File | Description |
|------|-------------|
| `.zshrc` | Zsh config with Oh My Zsh, OS-conditional aliases |
| `.zprofile` | Homebrew init (macOS only) |
| `.nanorc` | Nano editor config with OS-aware syntax paths |
| `.gitconfig` | Git user config |
| `.gitignore` | Global gitignore |
| `.ssh/config` | SSH hosts with 1Password agent (OS-aware socket path) |
| `.config/1Password/ssh/agent.toml` | 1Password SSH agent vault config |
| `Scripts/` | Utility scripts (macOS only) |

## Updating

```bash
chezmoi update
```

## Adding New Files

```bash
chezmoi add ~/.some-config
```

For templated files:

```bash
chezmoi add --template ~/.some-config
```

## Structure

- `dot_*` / `dot_*.tmpl` — config files (`.tmpl` = OS-aware templates)
- `private_dot_*` — private files (mode 0600)
- `.chezmoiexternal.toml` — external dependencies (Oh My Zsh)
- `.setup/ansible/` — Ansible playbook for package installation
- `run_once_before_install.sh.tmpl` — bootstrap script (runs once on first apply)
