# Blue Berry — Plan Forward

> **Source:** `SPEC.md` (v0.2), `MEMORY.md` (runbook), `.opencode/AGENTS.md`. Last updated `2026-08-28`.

---

## Current State (v0.2 Playable Loop)

- **Loop:** `StartScreen (dim 0.92, ALWAYS) 640×360` → `Main 2400×900 arena y_sort` → `Player 5HP 130 hop 64/0.28 i-frame 0.22 (clears layer-32 obstacles)` `WASD/Arrows + Space hop + X/Z attack 10×6.5 hitstop` → `Enemy chase 68 detection 220 lose 320 attack 22 sep` `HP3` → `Spawner 2 + every 2.2s max6 ring` → `HUD ♥/Wave/Kills` → `GameOverScreen pop → SPACE/R → reload → Start`.
- **Tech:** `load_steps` strict ordering, `set_deferred` for monitoring, `anim_name` fix, `60.0` float division, `_margin` ignore, `mouse_filter IGNORE` on BG, `ALWAYS` for UI, no `paused` freeze (DISABLED player).
- ** debt:** `SpriteFrames` placeholders on Enemy only (player movement on `rabbit_run.png` strip, `attack/hurt` still `blueberry_1.png`), `assets/sfx/` empty, `default_env` solid.
- **Done since v0.2:** arena `800×400→2400×900`, jump-over obstacles (crate/rock/log + KipperFalcon forest rocks/trees, layer 32), player art wired, tileable forest parallax with period-correct wrap.

---

## Next Sprints

### Sprint 1 — Art Swap & Juice (1–2 days)
**Goal:** Rabbit feels good; no new systems.
- [x] **Rabbit sheet (2026-09-18):** `blueberry_1.png` `64×64` wired as `Player.tscn` `SpriteFrames` `idle/run/hop/attack/hurt`.
- [x] **Rabbit run strip (2026-09-25):** `assets/sprites/rabbit_run.png` `1280×256` (5× `256×256`, bg cleared) wired as `idle` (frame 0) / `run` (5f @10fps) / `hop` (5f @12fps); sprite `pos 0,-10 scale 0.2`; hop rest pose via `_sprite_base_y`.
- [x] **Rabbit up/down art (2026-10-03):** `assets/sprites/rabbit_updown.png` `256×180` top-down single frame (black bg border-flood-cleared) wired as `run_up`/`run_down` (loop @10fps); `player.gd` picks by dominant axis, `scale.y` flipped when moving up, `facing` flip on `x` input only.
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
- [x] **2DPIXX pack intake (2026-10-03):** "Free 2D Isometric Fantasy Pack" (CC-BY-4.0, Jana Ochse) vendored as `assets/vendor/2dpixx/` (12 PNGs short-named + verbatim `LICENSE.TXT` + `ATTRIBUTION.md` with layout notes); `--import` exit 0. Forest sheet inspected: 5×5 of `128×128` (trees/bushes/stumps/logs/rock/tufts + iso ground BLOCKS with side faces — blocks unsuitable as flat ground, flora usable as props). See `Forest Floor Plan` below.
- [x] **Arena TileMap (2026-10-03):** tuft meadow instead of `16×16` TileSet — `GroundTiles` TileMapLayer (`scripts/ground.gd`, z -1, modulate 0.82) with runtime-built TileSet tiling `pix_tuft.png` (38×10 @0.5 = 64px, 6 flip/offset variants, deterministic seed); moss `Ground` ColorRect underlay (z -2, GroundGrid hidden). Tried grass cubes first — too neon as full quilt; tuft reads as scattered grass. Supersedes the TileMap sketch below.
- [ ] **Juice:** `StartScreen` intro tween already; add `GameOver` shake, `HUD` hearts pop `scale 1.2→1.0`.
- [ ] **Pause menu:** `scenes/PauseMenu.tscn` `CanvasLayer ALWAYS` `Esc → paused toggle` `Resume/Quit`.

### Sprint 4 — Systems & Content (stretch)
- [ ] **Nav:** `NavigationRegion2D` baked from TileSet, `Enemy` `NavigationAgent2D` `target=player` → `get_next_path_position` when not in `attack_range`.
- [ ] **Boss:** First boss `big berry` `HP 12` `speed 44` `burst 2` `arena center` on `wave 5`.
- [ ] **Mobile/Gamepad:** `InputMap` already Joy; add `TouchScreenButton` `hop/attack` anchors.
- [ ] **Save:** `ConfigFile` `kills/wave` high score.

---

## Forest Floor Plan (2DPIXX pack — field of trees & bushes)

**Goal look/feel:** flat grass arena dressed as a forest floor — trees and bushes
scattered around that the rabbit runs between while chasers hunt it. Ground
stays flat (existing base); flora are Y-sorted props, not a TileMap.

**Phase 1 — decor scatter (no gameplay change):**
1. `scenes/Flora.tscn` + `scripts/flora.gd`: `Node2D` root with `Sprite2D`
   (`AtlasTexture` cell from `tileset-forest.png`, centered, displayed `@0.5`
   ≈64px to sit with the chunky art) + exported `blocks: bool`.
   Non-blocking default (bushes, grass tufts, flowers): no collision.
2. `main.gd` seeded scatter (`RandomNumberGenerator`, fixed seed): ~20 bushes/
   tufts inside the `2400×900` arena, clear radius ~200px around player spawn,
   as children of a `Flora` Node2D under the already-`y_sort` arena so the
   rabbit/enemies pass correctly in front/behind.
3. Enemy spawner untouched (edge ring) — chasers run between the bushes.

**Built 2026-10-03 (Phases 1+2, as-built — supersedes the sketch above):**
- Cells pre-cut to `assets/sprites/forest/pix_*.png` (17 PNGs, offsets
  base-aligned from measured opaque bbox). `grass_1/2` are iso BLOCKS, excluded.
- `Flora.tscn` root is `StaticBody2D` (not `Node2D`): `decor` → layer 0 +
  shape disabled; `block` (tree_1..4, rock) → layer 1 = Walls (blocks player
  AND enemies, no hop-clear). Cosmetic flip_h + scale jitter (decor only).
- Flora are DIRECT children of Main (no container) so y_sort orders each prop
  vs the Player; enemies (in `$Enemies`, y≈0) always draw under flora — reads
  as chasers pushing through bushes, accepted.
- `main.gd`: `ARENA_SEED=20261003` seeded `rng` drives obstacles AND flora
  (deterministic layout); `_spawn_flora` 18 decor (`bush_1/2`, `tuft`) + 7
  blockers (central band `|x|<0.35W`, clear 220px, spacing 150); cleared via
  group `flora` on menu/start like obstacles.
- `obstacle.gd`: 7 hop-able `pix_*` variants (stump×3, logs×2, mound×2 @0.5)
  added to `RANDOM_TYPES` — hop clears them on layer 32 as before.
- StartScreen credit line (CC-BY-4.0) added. Verified: `--import` + `check`
  exit 0 / 0 warnings, `screenshot.gd` showcase re-captured (bush/tree/mound/
  rock/tuft all visible, dirt patches blend).

**Phase 2 — hop-able + blocking props (gameplay):**
4. Stumps/logs reuse the `Obstacle.tscn` layer-32 pattern (hop clears them);
   add forest `AtlasTexture` variants to `obstacle.gd` or a `Flora` blocker mode.
5. Trees/rocks become `StaticBody2D` blockers with trunk-sized (not canopy)
   `CollisionShape2D`, sparse placement away from the spawn ring. Caveat: chaser
   AI has no pathfinding and can snag on blockers — keep blockers few until
   Sprint 4 nav lands; separation steering already helps.
6. CC-BY-4.0 credit line ("Forest art: Jana Ochse (2DPIXX), www.2dpixx.de") on
   `StartScreen` + docs (required if the art ships).

**Explicitly out:** iso ground blocks as arena floor (side faces = raised-block
look, wrong for flat top-down); character sheets (archer/warrior/wizard) —
future enemy-variant option, not this plan.

**Verify per phase:** `--import` + headless `smoke` exit 0 / 0 warnings,
`screenshot.gd` showcase compare, `/run play` — rabbit weaves through flora,
hop clears logs, enemies still reach the player.

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

1. `git pull` → `.opencode/skills/run-game/run-game.sh import` → `.opencode/skills/run-game/run-game.sh smoke`, filter `WARNING` (per-OS paths in `MEMORY.md` §1; `GODOT_BIN` overrides the exe).
2. Check `MEMORY.md:2` boot flow; edit `.tscn` with `load_steps = ext+sub` ordering.
3. For hop/attack tuning: `player.gd:10` `hop_*` `attack_*`, `Main.tscn` Hitbox offset.
4. For UI: `StartScreen.tscn` `Center/VBox` `GameOverScreen.tscn` `HBox` `ALWAYS`.
5. Commit: `git add SPEC.md MEMORY.md .opencode/AGENTS.md README.md PLAN.md` + `scenes/` `scripts/`.

---

## Done When

- Splash → PLAYING → kill 6 → wave 2 → die → Game Over pop → SPACE → splash, no warnings, 60 FPS, hop dodges reliably, 3-hit combo feels tight.
