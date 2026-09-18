# Blue Berry — Cross-AI Project Spec

This file is the shared instruction contract for AI coding agents working on Blue Berry, including Codex and opencode. Keep it short and update it only when the project-wide rules change.

## Source Of Truth

Read these files before changing gameplay, scene structure, controls, or content:

1. `SPEC.md` — canonical implementation spec. This wins over every other design doc.
2. `MEMORY.md` — runbook, boot flow, UIDs, known Godot errors, and verification notes.
3. `PLAN.md` — current roadmap and next work.
4. `GDD.md` — high-level game intent and feel.
5. `parallax_spec.md` — parallax/background requirements when working on background scenes or assets.

If docs disagree, prefer `SPEC.md`, then update the stale doc as part of the same change.

## Project Summary

Blue Berry is a Godot 4.7.2 pixel-art beat 'em up / belt-scroll brawler. A rabbit hero uses hop-dodge i-frames and a front melee swipe to survive swarming berry enemies.

- Engine: Godot 4.7.2, GDScript only.
- Renderer: GL Compatibility.
- Entry scene: `res://scenes/Main.tscn`.
- Resolution: `640x360` viewport, `1280x720` window override, `canvas_items` stretch.
- Pixel rules: nearest texture filtering, pixel-snapped 2D feel, no smoothing on pixel assets.

## Repository Map

- `project.godot` — engine, input map, main scene.
- `scenes/` — Godot scenes. Keep scene/script ownership clear.
- `scripts/` — one GDScript per major scene.
- `assets/` — sprites, backgrounds, environment/vendor art, future SFX.
- `shaders/` — pixel/palette/ground shaders.
- `SPEC.md`, `MEMORY.md`, `PLAN.md`, `GDD.md` — project docs.
- `AGENTS.md` — root AI entry point.
- `.opencode/AGENTS.md` — opencode entry point.

## Implementation Rules

- Use GDScript only unless the user explicitly asks otherwise.
- Prefer existing scene and script patterns over new architecture.
- Keep one main script per scene and use signals over broad tree searches.
- Use `snake_case` for GDScript variables/functions, `PascalCase` for node names, and lowercase groups such as `"player"` and `"enemy"`.
- Use `@onready` node references and null guards for optional scene nodes.
- Use `set_deferred()` for collision, monitoring, or disabled changes that may occur during physics query flushes.
- UI that must respond while gameplay is frozen should use `PROCESS_MODE_ALWAYS`; freeze gameplay nodes with process modes, not by relying on global pause unless a pause system is being implemented.
- Preserve collision layer intent:
  - `1` world
  - `2` player hurtbox
  - `4` player attack
  - `8` enemy hurtbox
  - `16` enemy attack
  - `32` obstacle (StaticBody; player body mask `33` normally, drops to `1` during HOP so hops clear crates/rocks/logs)
- Preserve the boot loop: `START -> PLAYING -> GAME_OVER -> reload/menu -> START`.

## Godot Scene Rules

- Be careful editing `.tscn` by hand.
- Keep resource order as `[gd_scene]`, then all `[ext_resource]`, then all `[sub_resource]`, then `[node]`.
- Keep `load_steps` consistent with resource counts.
- Do not manually edit Godot import hashes or generated `.godot/` cache files.
- Keep committed `.import` files when assets are imported, because they stabilize UIDs.

## Verification

Use the local Godot executable available on the machine (Windows `Gadot` builds vs macOS `/Applications/Godot.app/...` — exact commands per OS in `MEMORY.md` §1).

Preferred checks (from the repo root):

```sh
godot --headless --path . --import
godot --headless --path . --quit --verbose
```

Expected result: no parser errors and no new warnings. If Godot is unavailable, state that clearly in the final response.

## Signed Commits

When creating commits on this machine, use the local opencode skill at:

`$HOME/.config/opencode/skills/gpg-signed-commits/SKILL.md`

Rules from that skill:

- Never create an unsigned commit.
- Resolve the wrapper with `WRAPPER="$HOME/.config/opencode/skills/gpg-signed-commits/gpg-with-passphrase.sh"`.
- Ensure the wrapper is configured as `gpg.program`.
- Use `git commit -S ...` explicitly, even when `commit.gpgsign=true`.
- For amend/rebase/cherry-pick/merge commits, use the signed equivalents such as `git commit --amend -S --no-edit` and `git rebase --gpg-sign`.
- Verify after committing with `git log -1 --show-signature`.
- Never print, echo, log, or store the GPG passphrase or `$GPG` value.
- If signing fails, ask the user rather than falling back to an unsigned commit.

## Documentation Policy

When changing mechanics, controls, scene hierarchy, collision layers, or asset pipeline:

- Update `SPEC.md` first.
- Update `MEMORY.md` for runbook or bug-fix knowledge.
- Update `PLAN.md` when roadmap status changes, and when adding features or tasks.
- When adding new scenes, scripts, or files: update `MEMORY.md` §4 (Key Files & UIDs) and `AGENTS.md` Important Files if it is a major scene/script, so every agent file stays in sync.
- Keep `AI_SPEC.md`, `AGENTS.md`, and `.opencode/AGENTS.md` focused on agent behavior, not detailed game design.

## Current Gameplay Contract

- Player: rabbit, `5 HP`, 8-direction movement, hop dodge (clears layer-32 obstacles), front attack, hurt/death states.
- Enemy: basic chaser, wander/chase/attack/hurt/dead states.
- Main: owns start screen, HUD, spawner, game-over flow, and the `2400×900` arena.
- Obstacles: jump-over crate/rock/log plus KipperFalcon forest rocks/trees (`Obstacle.tscn`/`obstacle.gd`), random type, layer 32.
- Controls: WASD/arrows move, Space hop, X/Z attack, UI accept for screens.
- Core feel: readable hitboxes, hop as defense, swarm pressure, crisp pixel presentation.
