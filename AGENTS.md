# Blue Berry — AI Agent Instructions

This is the root instruction file for Codex and other repository-aware agents. opencode also has `.opencode/AGENTS.md`, which points back to the same shared rules.

## Read First

1. `AI_SPEC.md` — cross-agent rules and project contract.
2. `SPEC.md` — canonical implementation spec and gameplay truth.
3. `MEMORY.md` — runbook, boot flow, common Godot errors, verification.
4. `PLAN.md` — roadmap and current next steps.

Follow `SPEC.md` if any docs conflict, then update stale docs in the same change.

## Working Rules

- Treat this as a Godot 4.7.2 GDScript-only project.
- Keep changes scoped and consistent with the current scene/script layout.
- Do not commit or edit `.godot/` cache output.
- When asked to commit, follow the GPG signing skill at `$HOME/.config/opencode/skills/gpg-signed-commits/SKILL.md`: use `git commit -S`, verify with `git log -1 --show-signature`, and never create unsigned commits.
- Preserve pixel-art settings: nearest filtering, `640x360` base viewport, GL Compatibility.
- Keep `.tscn` resource ordering valid: `ext_resource` before `sub_resource` before `node`.
- Verify with headless Godot import/quit when available.

## Important Files

- `project.godot` — main scene and engine settings.
- `scenes/Main.tscn` + `scripts/main.gd` — game state, HUD, spawner, start/game-over flow.
- `scenes/Player.tscn` + `scripts/player.gd` — rabbit controls, hop, attack, health.
- `scenes/Enemy.tscn` + `scripts/enemy.gd` — chaser AI and combat.
- `scenes/StartScreen.tscn`, `scenes/GameOverScreen.tscn` — shell flow UI.
- `scenes/Background.tscn`, `scenes/Parallax*.tscn`, `scripts/background.gd`, `parallax_spec.md` — background/parallax work.

## Before Finishing

- When adding features, tasks, or new files, sync `SPEC.md` / `MEMORY.md` / `PLAN.md` per `AI_SPEC.md` Documentation Policy so every agent shares one contract.
- Mention any docs updated.
- Mention whether Godot verification was run.
- If verification could not run, say why.
