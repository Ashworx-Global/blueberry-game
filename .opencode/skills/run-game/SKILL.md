---
name: run-game
description: Run the Blue Berry Godot game via the run-game script (play, editor, headless verify).
---

# Run Game

Launch Blue Berry through the versioned runner script so every agent
(and human) uses the same Godot invocation. Prefer this over ad-hoc
`godot ...` commands.

## Script

- `.opencode/skills/run-game/run-game.sh` — macOS / Linux / Git Bash.
- `.opencode/skills/run-game/run-game.ps1` — Windows PowerShell.

Both resolve the repo root from the script location (must contain
`project.godot`) and resolve the Godot executable in this order:

1. `$GODOT_BIN` / `$env:GODOT_BIN` (explicit override, always wins).
2. macOS: `/Applications/Godot.app/Contents/MacOS/Godot`.
3. Windows: `C:\Dev\Gadot\Godot_v4.7.2-stable_win64_console.exe`.
4. `godot` on `PATH`.

## Modes

| Mode | Command | When to use |
|------|---------|-------------|
| `play` (default) | `run-game.sh play` | Play the game (`godot --path <repo>`, entry `scenes/Main.tscn`). Opens a window — do NOT use for headless agents. |
| `editor` | `run-game.sh editor` | Open the project in the Godot editor (`-e`). |
| `import` | `run-game.sh import` | Headless `--import`. Run after adding/replacing art, before verify. |
| `check` | `run-game.sh check` | Headless `--check-only --quit` parse check (`--quit` is required: bare `--check-only` never terminates on Godot 4.7.2). |
| `smoke` | `run-game.sh smoke` | Headless `--quit --verbose` boot smoke test. Filter output for `WARNING`/`ERROR` (`grep` on macOS/Linux, `Select-String` on PowerShell). |

Extra args after `--` are forwarded to Godot:

```sh
.opencode/skills/run-game/run-game.sh smoke -- --verbose
```

## Rules

- Run from anywhere; the script finds the repo root itself. Never open
  the parent folder as the Godot project — always `--path <repo>`.
- Expected result for `check`/`smoke`: no parser errors, no new warnings
  (see `MEMORY.md` §1). If Godot is unavailable, say so in the final
  response instead of claiming verification passed.
- Never commit `.godot/` cache output (see `.gitignore`).
- `main` is protected: do this work on a `feat/*` branch, never push
  directly to `main`.
