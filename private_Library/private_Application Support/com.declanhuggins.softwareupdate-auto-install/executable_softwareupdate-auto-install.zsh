#!/bin/zsh
set -u

PATH="/usr/bin:/bin:/usr/sbin:/sbin"
SOFTWAREUPDATE="/usr/sbin/softwareupdate"
LOG_DIR="$HOME/Library/Logs/softwareupdate-auto-install"
CACHE_DIR="$HOME/Library/Caches"
LOCK_DIR="$CACHE_DIR/softwareupdate-auto-install.lock"
LOCK_PID_FILE="$LOCK_DIR/pid"
LOG_FILE="$LOG_DIR/run.log"
LIST_FILE="$CACHE_DIR/softwareupdate-auto-install-list.txt"

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

run_step() {
  local label="$1"
  shift

  echo "[$(timestamp)] START $label"
  "$@"
  local step_rc=$?
  if [[ "$step_rc" -eq 0 ]]; then
    echo "[$(timestamp)] OK $label"
  else
    echo "[$(timestamp)] FAIL $label status=$step_rc"
  fi

  return "$step_rc"
}

echo "[$(timestamp)] softwareupdate-auto-install invoked"

if [[ ! -x "$SOFTWAREUPDATE" ]]; then
  echo "[$(timestamp)] softwareupdate not found"
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
  echo "[$(timestamp)] Another softwareupdate-auto-install run is already active; exiting"
  exit 0
fi
trap 'rm -f "$LIST_FILE" "$LOCK_PID_FILE"; rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

if [[ "${AUTOUPDATE_FOREGROUND:-0}" != "1" ]] && pmset -g batt | head -n 1 | grep -q "Battery Power"; then
  echo "[$(timestamp)] On battery power; skipping this run"
  exit 0
fi

if pgrep -x softwareupdate >/dev/null 2>&1; then
  echo "[$(timestamp)] Another softwareupdate command is currently running; skipping this run"
  exit 0
fi

echo "[$(timestamp)] Checking available Apple software updates"
if ! "$SOFTWAREUPDATE" --list > "$LIST_FILE" 2>&1; then
  echo "[$(timestamp)] softwareupdate --list failed"
  cat "$LIST_FILE"
  exit 0
fi

if grep -q "No new software available" "$LIST_FILE"; then
  echo "[$(timestamp)] No Apple software updates available"
  exit 0
fi

cat "$LIST_FILE"
run_step "softwareupdate install all" "$SOFTWAREUPDATE" --install --all --agree-to-license || true

echo "[$(timestamp)] softwareupdate-auto-install completed"
exit 0
