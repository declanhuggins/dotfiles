#!/bin/bash
set -euo pipefail

if ! command -v docker &>/dev/null; then
  exit 0
fi

# Zsh: generate into Oh My Zsh completions dir (auto-sourced via FPATH)
if [ -d "$HOME/.oh-my-zsh" ]; then
  mkdir -p "$HOME/.oh-my-zsh/completions"
  docker completion zsh > "$HOME/.oh-my-zsh/completions/_docker"
fi

# Bash: generate into standard bash-completion user dir
mkdir -p "$HOME/.local/share/bash-completion/completions"
docker completion bash > "$HOME/.local/share/bash-completion/completions/docker"
