#!/usr/bin/env bash
set -e

if [[ "$(uname)" != "Darwin" ]]; then
  exit 0
fi

source "$HOME/.dotfiles/config/hostname.conf"

sudo scutil --set ComputerName "$PRETTY_NAME"
sudo scutil --set HostName "$HOSTNAME"
sudo scutil --set LocalHostName "$HOSTNAME"