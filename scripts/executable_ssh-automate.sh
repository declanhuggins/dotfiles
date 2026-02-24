#!/bin/bash
# Minimal SSH wrapper for VS Code Remote-SSH using 1Password and sshpass.

set -euo pipefail

# If the first argument is "-V", simply output the SSH version.
if [[ "${1:-}" == "-V" ]]; then
  exec ssh -V
fi

# Ensure at least one argument is provided.
if [[ "$#" -eq 0 ]]; then
  echo "Usage: $0 [ssh options] <SSH target>" >&2
  exit 1
fi

# The SSH target is assumed to be the last argument.
SSH_TARGET="${@: -1}"

# Retrieve the SSH password from 1Password (using --reveal) and strip newline characters.
# Fail fast if op is locked/not signed in or the item/field can't be read.
SSH_PASSWORD="$(op item get "$SSH_TARGET" --field "password" --reveal 2>/dev/null | tr -d '\r\n')" || {
  echo "[ssh-automate] Failed to read password from 1Password item '$SSH_TARGET'." >&2
  exit 10
}

if [[ -z "${SSH_PASSWORD}" ]]; then
  echo "[ssh-automate] Password field is empty for 1Password item '$SSH_TARGET'." >&2
  exit 11
fi

# Use sshpass to supply the retrieved password to ssh with all provided arguments.
# Limit prompts to avoid indefinite hangs in non-interactive contexts.
exec sshpass -p "$SSH_PASSWORD" ssh -o NumberOfPasswordPrompts=1 "$@"
