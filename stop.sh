#!/usr/bin/env sh
set -u

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BACKEND_BIN="$ROOT_DIR/a2a-server"
PID_FILE="$ROOT_DIR/a2a-server.pid"
STOPPED=0

is_backend_process() {
  TARGET_PID="$1"
  kill -0 "$TARGET_PID" 2>/dev/null || return 1

  PROCESS_EXE=$(readlink "/proc/$TARGET_PID/exe" 2>/dev/null || true)
  PROCESS_CWD=$(readlink -f "/proc/$TARGET_PID/cwd" 2>/dev/null || true)
  PROCESS_NAME=$(ps -p "$TARGET_PID" -o comm= 2>/dev/null | tr -d ' ' || true)

  case "$PROCESS_EXE" in
    "$BACKEND_BIN"|"$BACKEND_BIN (deleted)") return 0 ;;
  esac
  [ "$PROCESS_CWD" = "$ROOT_DIR" ] && [ "$PROCESS_NAME" = "a2a-server" ]
}

stop_backend_pid() {
  TARGET_PID="$1"
  if ! is_backend_process "$TARGET_PID"; then
    return 1
  fi

  kill "$TARGET_PID" 2>/dev/null || return 1
  WAIT_COUNT=0
  while kill -0 "$TARGET_PID" 2>/dev/null && [ "$WAIT_COUNT" -lt 10 ]; do
    WAIT_COUNT=$((WAIT_COUNT + 1))
    sleep 1
  done

  if kill -0 "$TARGET_PID" 2>/dev/null; then
    kill -9 "$TARGET_PID" 2>/dev/null || return 1
  fi

  echo "Go backend stopped (PID $TARGET_PID)."
  return 0
}

if [ -f "$PID_FILE" ]; then
  SAVED_PID=$(cat "$PID_FILE" 2>/dev/null || true)
  if [ -n "$SAVED_PID" ] && stop_backend_pid "$SAVED_PID"; then
    STOPPED=1
  fi
  rm -f "$PID_FILE"
fi

for FOUND_PID in $(pgrep -x a2a-server 2>/dev/null || true); do
  if stop_backend_pid "$FOUND_PID"; then
    STOPPED=1
  fi
done

if [ "$STOPPED" -eq 0 ]; then
  echo "Go backend is not running."
fi

exit 0
