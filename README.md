# dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/) and [Ansible](https://www.ansible.com/).

Supports **macOS**, **Ubuntu**, and **Arch Linux**.

## New Machine Setup

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin init --apply declanhuggins/dotfiles
```

During `chezmoi init`, you'll be prompted:

- **"Do you have sudo access on this machine"** — `n` runs a lightweight setup (installs fastfetch to `~/.local/bin`, skips Ansible)
- **"Is this a Notre Dame student machine"** — `y` adds `/escnfs/home/pbui/pub/pkgsrc/bin` to PATH except on `db8` / `db8.cse.nd.edu`
- **"Will you use 1Password on this machine"** — `n` skips 1Password SSH agent config and agent.toml
- **"Configure UGREEN NAS SMB automounts"** — `y` adds a macOS user LaunchAgent for `Photography`, `Games`, and `Media`

To change these answers later, edit `~/.config/chezmoi/chezmoi.toml`.

### What happens on first run

1. Clones this repo and prompts for machine configuration
2. Runs bootstrap script:
   - **With sudo:** installs Homebrew (macOS), enables Touch ID (macOS), installs zsh, sets default shell, runs Ansible playbook (git, nano, curl, wget, cmatrix, fastfetch)
   - **Without sudo:** installs fastfetch to `~/.local/bin` (`.bashrc` auto-launches zsh)
3. Pulls Oh My Zsh
4. Applies all config files with OS-appropriate settings

## Updating

```bash
chezmoi update
```

To save edits made directly to managed files on a machine, use `chezmoi re-add`.
Templated files need their changes merged into the source template manually. Review
`chezmoi diff` before committing and pushing the source repository.

## Re-running Bootstrap

```bash
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

## UGREEN NAS Automounts

On macOS machines with Tailscale access, enable `setupNasAutomount` in
`~/.config/chezmoi/chezmoi.toml` to configure a user-session LaunchAgent that
keeps these SMB shares mounted:

```text
/Volumes/Photography
/Volumes/Games
/Volumes/Media
```

The defaults use `smb://nas` with the current macOS username. To change that,
edit:

```toml
[data]
  setupNasAutomount = true
  nasSmbHost = "nas"
  nasSmbUser = "hugs"
```

The mounter runs as your login user so it can use your normal macOS SMB
Keychain entry. If cleanup from an older autofs setup is skipped because sudo
is not cached, run:

```bash
sudo -v && chezmoi apply
```

## What's Managed

| File | Description |
|------|-------------|
| `.zshrc` | Zsh config with Oh My Zsh, OS-conditional aliases |
| `.bashrc` | Auto-switches to zsh, fallback config if zsh unavailable |
| `.bash_profile` | Sources `.bashrc` for login shells |
| `.zprofile` | Homebrew init (macOS only) |
| `.nanorc` | Nano editor config with OS-aware syntax paths |
| `.gitconfig` | Git user config |
| `.gitignore` | Global gitignore |
| `.ssh/config` | SSH hosts, 1Password agent (if enabled) |
| `.config/1Password/ssh/agent.toml` | 1Password SSH agent vault config (if enabled) |
| `run_after_configure_nas_automount.sh.tmpl` | macOS cleanup and LaunchAgent loading for UGREEN NAS SMB shares |
| `.local/bin/mount-nas-shares` | User-session SMB mounter used by the NAS LaunchAgent |
| `Library/LaunchAgents/` | macOS schedules for Homebrew, global Node packages, macOS updates, and NAS mounts |
| `Library/Application Support/com.declanhuggins.*/` | Automatic updater scripts |
| `scripts/` | Utility scripts (per-OS, see `.chezmoiignore`) |

## Adding New Files

```bash
chezmoi add ~/.some-config
chezmoi add --template ~/.some-config  # for templated files
```

## Structure

- `dot_*` / `dot_*.tmpl` — config files (`.tmpl` = OS-aware templates)
- `private_dot_*` — private files (mode 0600)
- `.chezmoiexternal.toml` — external dependencies (Oh My Zsh)
- `.setup/ansible/` — Ansible playbook for package installation
- `run_once_before_install.sh.tmpl` — bootstrap script (runs once on first apply)
- `.chezmoiignore` — controls which files deploy per OS
