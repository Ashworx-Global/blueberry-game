---
description: Run Blue Berry via the run-game script (default headless smoke test)
---

Load the `run-game` skill, then run `.opencode/skills/run-game/run-game.sh`
(`run-game.ps1` on Windows PowerShell) with mode `$ARGUMENTS` — default to
`smoke` when no argument is given.

Modes: `play` (game window) | `editor` | `import` | `check` | `smoke`
(headless boot test, the default).

Rules:
- `play` and `editor` open a Godot window and block — say so and prefer
  `smoke`/`check` for headless verification.
- For `check`/`smoke`, report success only when output is free of
  `WARNING`/`ERROR` (filter with `grep` on macOS/Linux, `Select-String` on
  PowerShell). If Godot is unavailable, say so instead of claiming a pass.
- Never commit `.godot/` cache output.
