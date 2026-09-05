#!/bin/zsh
set -u

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
BREW="/opt/homebrew/bin/brew"
LOG_DIR="$HOME/Library/Logs/brew-auto-update"
CACHE_DIR="$HOME/Library/Caches"
LOCK_DIR="$CACHE_DIR/brew-auto-update.lock"
LOCK_PID_FILE="$LOCK_DIR/pid"
LOG_FILE="$LOG_DIR/run.log"

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

echo "[$(timestamp)] brew-auto-update invoked"

if [[ ! -x "$BREW" ]]; then
  echo "[$(timestamp)] Homebrew not found at $BREW"
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
  echo "[$(timestamp)] Another brew-auto-update run is already active; exiting"
  exit 0
fi
trap 'rm -f "$LOCK_PID_FILE"; rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

if [[ "${AUTOUPDATE_FOREGROUND:-0}" != "1" ]] && pmset -g batt | head -n 1 | grep -q "Battery Power"; then
  echo "[$(timestamp)] On battery power; skipping this run"
  exit 0
fi

if pgrep -x brew >/dev/null 2>&1; then
  echo "[$(timestamp)] Another brew command is currently running; skipping this run"
  exit 0
fi

export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS_THIS_RUN=1
export NONINTERACTIVE=1

overall_rc=0

run_step "brew update" "$BREW" update --quiet || overall_rc=1
run_step "brew upgrade" "$BREW" upgrade --quiet || overall_rc=1
run_step "brew autoremove" "$BREW" autoremove --quiet || overall_rc=1
run_step "brew cleanup" "$BREW" cleanup --quiet --prune=7 || overall_rc=1

if [[ "$overall_rc" -eq 0 ]]; then
  echo "[$(timestamp)] brew-auto-update completed"
else
  echo "[$(timestamp)] brew-auto-update completed with one or more failed steps"
fi

exit 0
