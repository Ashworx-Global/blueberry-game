#!/bin/sh
# Blue Berry — play the game (windowed).
# Usage: ./tools/run-game.sh [-- extra godot args...]
# Runs: <godot> --path <repo-root>
# Env override: GODOT_BIN=/path/to/Godot ./tools/run-game.sh
set -eu

# Repo root = parent of this script's directory (tools/).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ ! -f "$ROOT/project.godot" ]; then
  echo "run-game: could not locate project.godot under $ROOT" >&2; exit 2
fi

# Resolve the Godot ("Gadot" on Windows) executable.
if [ -z "${GODOT_BIN:-}" ]; then
  if [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
  elif command -v godot >/dev/null 2>&1; then
    GODOT_BIN="godot"
  elif [ -x "/c/Dev/Gadot/Godot_v4.7.2-stable_win64.exe" ]; then
    GODOT_BIN="/c/Dev/Gadot/Godot_v4.7.2-stable_win64.exe"
  elif [ -x "C:/Dev/Gadot/Godot_v4.7.2-stable_win64.exe" ]; then
    GODOT_BIN="C:/Dev/Gadot/Godot_v4.7.2-stable_win64.exe"
  else
    echo "run-game: no Godot executable found." >&2
    echo "  Set GODOT_BIN=/path/to/Godot (macOS: /Applications/Godot.app/Contents/MacOS/Godot," >&2
    echo "  Windows: C:\\Dev\\Gadot\\Godot_v4.7.2-stable_win64.exe)" >&2
    exit 2
  fi
fi

echo "+ $GODOT_BIN --path $ROOT $*"
exec "$GODOT_BIN" --path "$ROOT" "$@"
