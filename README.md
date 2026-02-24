# dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/) and [Ansible](https://www.ansible.com/).

Supports **macOS**, **Ubuntu**, and **Arch Linux**.

## New Machine Setup

### macOS

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply declanhuggins/dotfiles
```

This will install Homebrew (if needed), enable Touch ID for sudo, install zsh + Oh My Zsh, and apply all configs.

### Arch Linux / Ubuntu (with sudo)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply declanhuggins/dotfiles
```

If `chezmoi` isn't in your `$PATH` after install:

```bash
~/bin/chezmoi init --apply declanhuggins/dotfiles
```

### No sudo access (e.g. Notre Dame student machines)

Install chezmoi to a user-writable directory:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin init --apply declanhuggins/dotfiles
```

During `chezmoi init`, you'll be prompted:

- **"Is this a machine without sudo access"** — answer `y` to skip package installation and Ansible, and instead run a lightweight setup (attempts `chsh` without sudo, installs fastfetch to `~/.local/bin`)
- **"Is this a Notre Dame student machine"** — answer `y` to add `/escnfs/home/pbui/pub/pkgsrc/bin` to your PATH

To change these answers later, edit `~/.config/chezmoi/chezmoi.toml`.

### What happens on first run

1. Installs chezmoi
2. Clones this repo
3. Prompts for machine configuration (sudo access, student machine)
4. Runs bootstrap script (`run_once_before_install.sh`):
   - **With sudo:** installs Homebrew (macOS), enables Touch ID (macOS), installs zsh, sets default shell, runs Ansible playbook (git, nano, curl, wget, fastfetch)
   - **Without sudo:** attempts `chsh` without sudo (falls back to `.bashrc` auto-launching zsh), installs fastfetch to `~/.local/bin`
5. Pulls Oh My Zsh
6. Applies all config files with OS-appropriate settings

## Updating

```bash
chezmoi update
```

## What's Managed

| File | Description |
|------|-------------|
| `.zshrc` | Zsh config with Oh My Zsh, OS-conditional aliases |
| `.bashrc` | Auto-switches to zsh, fallback config if zsh unavailable |
| `.zprofile` | Homebrew init (macOS only) |
| `.nanorc` | Nano editor config with OS-aware syntax paths |
| `.gitconfig` | Git user config |
| `.gitignore` | Global gitignore |
| `.ssh/config` | SSH hosts with 1Password agent (OS-aware socket path) |
| `.config/1Password/ssh/agent.toml` | 1Password SSH agent vault config |
| `scripts/` | Utility scripts (per-OS, see `.chezmoiignore`) |

## Adding New Files

```bash
chezmoi add ~/.some-config
```

For templated files:

```bash
chezmoi add --template ~/.some-config
```

## Adding OS-Specific Scripts

Drop the script in `scripts/` with the `executable_` prefix (e.g., `executable_my-script.sh`), then add it to the appropriate section in `.chezmoiignore`.

## Re-running Bootstrap

```bash
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

## Structure

- `dot_*` / `dot_*.tmpl` — config files (`.tmpl` = OS-aware templates)
- `private_dot_*` — private files (mode 0600)
- `.chezmoiexternal.toml` — external dependencies (Oh My Zsh)
- `.setup/ansible/` — Ansible playbook for package installation
- `run_once_before_install.sh.tmpl` — bootstrap script (runs once on first apply)
- `.chezmoiignore` — controls which files deploy per OS
