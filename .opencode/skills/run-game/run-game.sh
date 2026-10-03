#!/bin/sh
# Blue Berry — run the game via Godot (macOS / Linux / Git Bash).
# Usage: run-game.sh [play|editor|import|check|smoke] [-- extra godot args...]
#   play    launch the game window (default)
#   editor  open the project in the Godot editor
#   import  headless --import (run after adding/replacing art)
#   check   headless --check-only (parse check, no window)
#   smoke   headless --quit --verbose (boot smoke test; filter WARNING|ERROR)
# Env override: GODOT_BIN=/path/to/Godot ./run-game.sh play
set -eu

MODE="${1:-play}"
if [ "$MODE" = "--" ]; then MODE="play"; fi
case "$MODE" in
  play|editor|import|check|smoke|help|-h|--help) ;;
  -*) MODE="play" ;; # first arg is a godot flag, not a mode
  *) echo "Unknown mode: $MODE (expected play|editor|import|check|smoke)" >&2; exit 2 ;;
esac
if [ $# -gt 0 ] && [ "$1" = "$MODE" ]; then shift; fi
if [ "${1:-}" = "--" ]; then shift; fi

# Repo root = three levels above this script (.opencode/skills/run-game/).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ ! -f "$ROOT/project.godot" ]; then
  # Fallback: walk up from CWD looking for project.godot
  D="$(pwd)"
  while [ "$D" != "/" ]; do
    if [ -f "$D/project.godot" ]; then ROOT="$D"; break; fi
    D="$(dirname "$D")"
  done
fi
if [ ! -f "$ROOT/project.godot" ]; then
  echo "run-game: could not locate project.godot (repo root)" >&2; exit 2
fi

# Resolve the Godot executable.
if [ -z "${GODOT_BIN:-}" ]; then
  if [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
  elif command -v godot >/dev/null 2>&1; then
    GODOT_BIN="godot"
  elif [ -x "/c/Dev/Gadot/Godot_v4.7.2-stable_win64_console.exe" ]; then
    GODOT_BIN="/c/Dev/Gadot/Godot_v4.7.2-stable_win64_console.exe"
  elif [ -x "C:/Dev/Gadot/Godot_v4.7.2-stable_win64_console.exe" ]; then
    GODOT_BIN="C:/Dev/Gadot/Godot_v4.7.2-stable_win64_console.exe"
  else
    echo "run-game: no Godot executable found." >&2
    echo "  Set GODOT_BIN=/path/to/Godot (macOS: /Applications/Godot.app/Contents/MacOS/Godot)" >&2
    exit 2
  fi
fi

run() { echo "+ $GODOT_BIN $*"; exec "$GODOT_BIN" "$@"; }

case "$MODE" in
  help|-h|--help)
    sed -n '2,9p' "$0" | sed 's/^# \?//'
    ;;
  play)   run --path "$ROOT" "$@" ;;
  editor) run --path "$ROOT" -e "$@" ;;
  import) run --headless --path "$ROOT" --import "$@" ;;
  # NOTE: bare --check-only never terminates on Godot 4.7.2; --quit makes it exit.
  check)  run --headless --path "$ROOT" --check-only --quit "$@" ;;
  smoke)  run --headless --path "$ROOT" --quit --verbose "$@" ;;
esac
