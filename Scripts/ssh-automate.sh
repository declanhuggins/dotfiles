#!/bin/bash
# Minimal SSH wrapper for VS Code Remote-SSH using 1Password and sshpass.

# If the first argument is "-V", simply output the SSH version.
if [ "$1" == "-V" ]; then
  ssh -V
  exit 0
fi

# Ensure at least one argument is provided.
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 [ssh options] <SSH target>"
  exit 1
fi

# The SSH target is assumed to be the last argument.
SSH_TARGET="${@: -1}"

# Retrieve the SSH password from 1Password (using --reveal) and strip newline characters.
SSH_PASSWORD=$(op item get "$SSH_TARGET" --field "password" --reveal | tr -d '\r\n')

# Use sshpass to supply the retrieved password to ssh with all provided arguments.
exec sshpass -p "$SSH_PASSWORD" ssh "$@"