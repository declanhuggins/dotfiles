#!/bin/zsh
set -u

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
NODE="/opt/homebrew/bin/node"
NPM="/opt/homebrew/bin/npm"
NCU="/opt/homebrew/bin/ncu"
LOG_DIR="$HOME/Library/Logs/node-global-auto-update"
CACHE_DIR="$HOME/Library/Caches"
LOCK_DIR="$CACHE_DIR/node-global-auto-update.lock"
LOCK_PID_FILE="$LOCK_DIR/pid"
LOG_FILE="$LOG_DIR/run.log"
UPDATES_JSON="$CACHE_DIR/node-global-auto-update.json"
PACKAGES_FILE="$CACHE_DIR/node-global-auto-update-packages.txt"

mkdir -p "$LOG_DIR" "$CACHE_DIR"

if [[ -f "$LOG_FILE" ]]; then
  log_size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
  if [[ "$log_size" -gt 1048576 ]]; then
    tail -n 2000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
  fi
fi

if [[ "${AUTOUPDATE_FOREGROUND:-0}" == "1" ]]; then
  exec > >(tee -a "$LOG_FILE") 2>&1
else
  exec >> "$LOG_FILE" 2>&1
fi

timestamp() {
  date "+%Y-%m-%d %H:%M:%S %z"
}

echo "[$(timestamp)] node-global-auto-update invoked"

if [[ ! -x "$NODE" || ! -x "$NPM" || ! -x "$NCU" ]]; then
  echo "[$(timestamp)] Required command missing; node=$NODE npm=$NPM ncu=$NCU"
  exit 0
fi

acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    print -r -- "$$" > "$LOCK_PID_FILE"
    return 0
  fi

  local lock_pid=""
  [[ -f "$LOCK_PID_FILE" ]] && lock_pid=$(<"$LOCK_PID_FILE")
  if [[ "$lock_pid" == <-> ]] && kill -0 "$lock_pid" 2>/dev/null; then
    return 1
  fi

  rm -f "$LOCK_PID_FILE"
  rmdir "$LOCK_DIR" 2>/dev/null || return 1
  mkdir "$LOCK_DIR" 2>/dev/null || return 1
  print -r -- "$$" > "$LOCK_PID_FILE"
}

if ! acquire_lock; then
  echo "[$(timestamp)] Another node-global-auto-update run is already active; exiting"
  exit 0
fi
trap 'rm -f "$UPDATES_JSON" "$PACKAGES_FILE" "$LOCK_PID_FILE"; rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

if [[ "${AUTOUPDATE_FOREGROUND:-0}" != "1" ]] && pmset -g batt | head -n 1 | grep -q "Battery Power"; then
  echo "[$(timestamp)] On battery power; skipping this run"
  exit 0
fi

if pgrep -x npm >/dev/null 2>&1; then
  echo "[$(timestamp)] Another npm command is currently running; skipping this run"
  exit 0
fi

export NO_UPDATE_NOTIFIER=1
export NPM_CONFIG_AUDIT=false
export NPM_CONFIG_FUND=false
export NPM_CONFIG_UPDATE_NOTIFIER=false

echo "[$(timestamp)] Checking global npm updates"
if ! "$NCU" -g --jsonUpgraded --loglevel silent > "$UPDATES_JSON"; then
  echo "[$(timestamp)] ncu failed while checking global packages"
  exit 0
fi

if [[ ! -s "$UPDATES_JSON" ]]; then
  echo "[$(timestamp)] Global npm packages are already up to date"
  exit 0
fi

if ! "$NODE" -e '
const fs = require("fs");
const input = fs.readFileSync(process.argv[1], "utf8").trim();
if (!input) process.exit(0);
const updates = JSON.parse(input);
for (const [name, version] of Object.entries(updates)) {
  console.log(`${name}@${version}`);
}
' "$UPDATES_JSON" > "$PACKAGES_FILE"; then
  echo "[$(timestamp)] Failed to parse ncu update list"
  exit 0
fi

if [[ ! -s "$PACKAGES_FILE" ]]; then
  echo "[$(timestamp)] No installable global npm updates found"
  exit 0
fi

echo "[$(timestamp)] Installing global npm updates:"
sed 's/^/  /' "$PACKAGES_FILE"

packages=("${(@f)$(< "$PACKAGES_FILE")}")
if "$NPM" -g install -- "${packages[@]}"; then
  echo "[$(timestamp)] node-global-auto-update completed"
else
  echo "[$(timestamp)] npm install reported a failure"
fi

exit 0
