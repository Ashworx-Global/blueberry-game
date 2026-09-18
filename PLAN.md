# Blue Berry — Plan Forward

> **Source:** `SPEC.md` (v0.2), `MEMORY.md` (runbook), `.opencode/AGENTS.md`. Last updated `2026-08-28`.

---

## Current State (v0.2 Playable Loop)

- **Loop:** `StartScreen (dim 0.92, ALWAYS) 640×360` → `Main 2400×900 arena y_sort` → `Player 5HP 130 hop 64/0.28 i-frame 0.22 (clears layer-32 obstacles)` `WASD/Arrows + Space hop + X/Z attack 28×18 hitstop` → `Enemy chase 68 detection 220 lose 320 attack 22 sep` `HP3` → `Spawner 2 + every 2.2s max6 ring` → `HUD ♥/Wave/Kills` → `GameOverScreen pop → SPACE/R → reload → Start`.
- **Tech:** `load_steps` strict ordering, `set_deferred` for monitoring, `anim_name` fix, `60.0` float division, `_margin` ignore, `mouse_filter IGNORE` on BG, `ALWAYS` for UI, no `paused` freeze (DISABLED player).
- ** debt:** `SpriteFrames` placeholders on Enemy only (player wired to `blueberry_1.png`), `assets/sfx/` empty, `default_env` solid.
- **Done since v0.2:** arena `800×400→2400×900`, jump-over obstacles (crate/rock/log, layer 32), player art wired, tileable forest parallax with period-correct wrap.

---

## Next Sprints

### Sprint 1 — Art Swap & Juice (1–2 days)
**Goal:** Rabbit feels good; no new systems.
- [x] **Rabbit sheet (2026-09-18):** `blueberry_1.png` `64×64` wired as `Player.tscn` `SpriteFrames` `idle/run/hop/attack/hurt`.
- [ ] **Enemy skin:** `slime/bug` `16×16 @2×` for `Enemy.tscn` `idle/run/attack/hurt`.
- [ ] **Hitstop + flash:** Verify `player.gd:270 time_scale 0.08 0.05s` already; add enemy flash `0.12s` + `Camera shake 2px` on hit.
- [ ] **Hop feel:** Playtest `hop_distance 64→72` if short, `cooldown 0.45→0.38` if sticky.
- [ ] **SFX hook:** Add `AudioStreamPlayer` `sfx/hop.wav attack.wav hurt.wav` → `player.gd` play on `hop/start_attack/take_damage`.

- **Accept:** `F5` → splash → start → hop dodges, attack kills in 3 hits, no warnings.

### Sprint 2 — Combat Depth (3–5 days)
- [ ] **3-hit combo:** `player.gd` `combo 0..2` `combo_window 0.4s` → 3 distinct `AttackHitbox` offsets `16,24,20` + damage `1,1,2` + `hop-cancel` at 80% recovery (`attack_timer <=0.08` allow hop).
- [ ] **Blueberry pickup:** `scenes/Pickup.tscn` `Area2D` `blue 8×8` ring spawn `>5 kills` → `health++` or `score`. `main.gd` `pickup_scene` preload.
- [ ] **Spawns ramp:** `main.gd` `spawn_interval 2.2→1.4` decay `0.08 per wave` or `max_enemies 6→9` at `wave 3`.
- [ ] **Balance:** Tune `DAMAGE 1` vs `HP3` (3 hits) vs `hop iframes 0.22` — ensure swarm not impossible.

### Sprint 3 — World & Flow (2–3 days)
- [x] **Parallax forest base (2026-09-18):** procedural tileable set (`bg_distant 1280`, `forest 512`, `ground 256`, `fg 320` RGBA) wired in `Background.tscn`/`background.gd` with period-correct centered wrap for the 2400px arena. Hand-tweak in Clip Studio per `parallax_spec.md` §10.
- [ ] **Arena TileMap:** Replace `Ground ColorRect` with `TileMapLayer` `TileSet 16×16` `physics layer` walls same `Walls` pos; keep `y_sort`.
- [ ] **Juice:** `StartScreen` intro tween already; add `GameOver` shake, `HUD` hearts pop `scale 1.2→1.0`.
- [ ] **Pause menu:** `scenes/PauseMenu.tscn` `CanvasLayer ALWAYS` `Esc → paused toggle` `Resume/Quit`.

### Sprint 4 — Systems & Content (stretch)
- [ ] **Nav:** `NavigationRegion2D` baked from TileSet, `Enemy` `NavigationAgent2D` `target=player` → `get_next_path_position` when not in `attack_range`.
- [ ] **Boss:** First boss `big berry` `HP 12` `speed 44` `burst 2` `arena center` on `wave 5`.
- [ ] **Mobile/Gamepad:** `InputMap` already Joy; add `TouchScreenButton` `hop/attack` anchors.
- [ ] **Save:** `ConfigFile` `kills/wave` high score.

---

## Tech Debt & Fixes Log

| Date | Issue | Files | Note |
|------|-------|-------|------|
| 2026-08-28 | `sub_resource` before `ext_resource` parse fail | `Player.tscn 3→6 Enemy 3→7 Main 5→7` | header ordering strict |
| 2026-08-28 | `shadowing name` | `player.gd:166 enemy.gd:191` `name→anim_name` | Node.name |
| 2026-08-28 | `Integer division` | `player.gd:84,142 /60.0 /80.0` | float |
| 2026-08-28 | `margin never used` | `main.gd:59 _margin` | prefix |
| 2026-08-28 | `monitoring while flushing` | `set_deferred` | `player.gd:208 enemy.gd:154` |
| 2026-08-28 | `splash never starts` | `WHEN_PAUSED → ALWAYS` `mouse_filter IGNORE` | `start_screen.gd:18` |
| 2026-08-28 | `StartButton blocked` | `BG mouse_filter` | `StartScreen.tscn:23` |

---

## How to Pick Up

1. `git pull` → `godot --headless --path . --import` → `godot --headless --path . --quit --verbose`, filter `WARNING` (per-OS paths in `MEMORY.md` §1).
2. Check `MEMORY.md:2` boot flow; edit `.tscn` with `load_steps = ext+sub` ordering.
3. For hop/attack tuning: `player.gd:10` `hop_*` `attack_*`, `Main.tscn` Hitbox offset.
4. For UI: `StartScreen.tscn` `Center/VBox` `GameOverScreen.tscn` `HBox` `ALWAYS`.
5. Commit: `git add SPEC.md MEMORY.md .opencode/AGENTS.md README.md PLAN.md` + `scenes/` `scripts/`.

---

## Done When

- Splash → PLAYING → kill 6 → wave 2 → die → Game Over pop → SPACE → splash, no warnings, 60 FPS, hop dodges reliably, 3-hit combo feels tight.
