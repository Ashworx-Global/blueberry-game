#!/bin/sh
# Blue Berry — run the game headless (boot smoke test).
# Usage: ./tools/run-headless.sh [-- extra godot args...]
# Runs: <godot> --headless --path <repo-root> --quit --verbose
# Env override: GODOT_BIN=/path/to/Godot ./tools/run-headless.sh
set -eu

# Repo root = parent of this script's directory (tools/).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ ! -f "$ROOT/project.godot" ]; then
  echo "run-headless: could not locate project.godot under $ROOT" >&2; exit 2
fi

# Resolve the Godot ("Gadot" on Windows) executable.
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
    echo "run-headless: no Godot executable found." >&2
    echo "  Set GODOT_BIN=/path/to/Godot (macOS: /Applications/Godot.app/Contents/MacOS/Godot," >&2
    echo "  Windows: C:\\Dev\\Gadot\\Godot_v4.7.2-stable_win64_console.exe)" >&2
    exit 2
  fi
fi

echo "+ $GODOT_BIN --headless --path $ROOT --quit --verbose $*"
exec "$GODOT_BIN" --headless --path "$ROOT" --quit --verbose "$@"
