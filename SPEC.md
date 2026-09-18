# Blue Berry — Game Specification (canonical v0.2)

> **Playable shell + splash/game-over loop.** Last updated `2026-08-28` (Godot 4.7.2, project root = repo root). `GDD.md` is high-level pitch; this file is source of truth for implementation.

---

## 1. Concept

A pixel-art **Beat 'em Up / Belt-Scroll Brawler** (Golden Axe-like). A rabbit hops to dodge encircling berry enemies, mobs them with a front swipe. Dark whimsy, crisp hitboxes, hop-as-defense.

**Pillars:** 1) Hop is defense (i-frames), 2) Readable melee (hitstop), 3) Swarm pressure (6 max enemies, ring spawns).

---

## 2. Engine / Project

- **Engine:** Godot 4.7.2 stable, GDScript only, `GL Compatibility` renderer (`project.godot:18`).
- **Entry:** `run/main_scene="res://scenes/Main.tscn"` (`uid://b1ueb3rry_main`) — `Main` owns splash/game-over via `CanvasLayer`.
- **Source root:** repo root (`project.godot` at repo root) — run with `godot --path <repo>` (see `MEMORY.md` §1 for per-OS executable paths) or VS Code `Launch Project (F5)`.
- **Display:** `viewport 640×360 → window 1280×720 (2×)`, `stretch canvas_items keep`, `default_texture_filter=0 Nearest`, `physics_ticks 60`.
- **Filtering:** Nearest, `snap_2d_transforms_to_pixel` implied via `canvas_items`.

### Input Map (`project.godot:14`)

| Action | Keys |
|--------|------|
| `move_left` | `A` `Left` `Joy Btn13 / Axis0 -1` |
| `move_right` | `D` `Right` `Joy Btn14 / Axis0 +1` |
| `move_up` | `W` `Up` `Joy Btn11 / Axis1 -1` |
| `move_down` | `S` `Down` `Joy Btn12 / Axis1 +1` |
| `hop` | `Space` `Joy Btn0` |
| `attack` | `X` `Z` `Joy Btn2` |

Also `ui_accept` (`Enter/Space`) for splash/game-over.

---

## 3. Core Loop

```
START (splash dim, player frozen) —SPACE/click→ PLAYING (HUD, spawner 2 + every 2.2s, max 6) ↔ HURT/HOP/ATTACK ↔ DEAD → GAME_OVER (overlay, freeze, stats) —SPACE/R → reload → START
```

Kill → score + `kills%6 → wave++`, `kills%8 → wave++` (spawner ramp, future decay).

---

## 4. Player — Rabbit (`scenes/Player.tscn` / `scripts/player.gd`)

- **Body:** `CharacterBody2D` `groups=["player"]` `collision layer 0 mask 33` (world 1 + obstacle 32); `CollisionShape2D` `Rect 14×20` at `0,-6`; `AnimatedSprite2D` `pos 0,-12 scale 2×` `texture_filter 0` wired to `blueberry_1.png` `SpriteFrames` (`ColorRect` placeholder body/ears/eyes kept as fallback); `Camera2D` `smoothing 6 drag 0.15`.
- **Exports:** `move_speed 130` `hop_distance 64 hop_duration 0.28 hop_cooldown 0.45 hop_iframes 0.22` `max_health 5 attack_damage 1 attack_cooldown 0.18 hurt_iframe 0.8 hurt_stun 0.35`.
- **State:** `enum State {IDLE,RUN,HOP,ATTACK,HURT,DEAD}` `health` `facing 1/-1` timers `hop_cooldown/hop/hop_iframe/attack/attack_cooldown/hurt/hurt_iframe` `hop_dir` `attack_hit_enemies`.
- **Movement:** `get_axis` → normalized `*130` → `move_and_slide`; `RUN/IDLE` anim; `facing` flips `sprite.scale.x` + `AttackHitbox.x`.
- **Hop:** `_start_hop:170` `dir = input or facing`, `HOP` `hop_timer 0.28` `iframes 0.22` `velocity dir*(64/0.28)` `Hurtbox monitoring=false` deferred `await 0.22 → true`, flicker `ticks/60.0%2`, retain `0.2` velocity. Cooldown `0.45+0.28`. Hop drops body mask to `1`, so the player sails over layer-32 obstacles (see §7).
- **Attack:** `_start_attack:193` `ATTACK` `timer 0.36` `await 0.08 → active true` `AttackHitbox 28×18 at 16,-10 layer4 mask8` → `await 0.12 → false`, root `0.15` speed, `cooldown 0.18`, one hit per swing `hit_enemies`, hitstop `time_scale 0.08 0.05s` `tween` none.
- **Damage:** `Hurtbox Area2D layer2 mask16` vs `enemy_attack 16`; `take_damage:212` ignores if `DEAD`/`hurt_iframe`/`hop_iframe`, `health--` `health_changed`, `HURT 0.35 i-frame 0.8` knock `180` flash tween, `_die:240` `DEAD` `Hurtbox false deferred` `Collision true deferred` `died` `modulate 0.6`.
- **Visual Hook:** `SpriteFrames` `idle/run/hop/attack/hurt` wired from `blueberry_1.png` (64×64) `Nearest` `Mipmaps Off`, names kept. Enemy still uses `ColorRect` placeholder.

### Physics

| Node | Type | Layer | Mask | Shape |
|------|------|-------|------|-------|
| `CollisionShape2D` | Body | — | — | `14×20` |
| `Hurtbox` | Area2D `player_hurtbox` | 2 | 16 | `14×20` |
| `AttackHitbox` | Area2D `player_attack` | 4 | 8 | `28×18` |

---

## 5. Enemy — Chaser (`scenes/Enemy.tscn` / `scripts/enemy.gd`)

- **Body:** `CharacterBody2D groups=["enemy"]` `Collision 14×18 at 0,-7`, `AnimatedSprite2D 0,-12 scale2`, `Body ColorRect 0.35,0.72,0.35`, `Hurtbox layer8 mask4 14×18`, `Hitbox layer16 mask2 22×14 at 14,-9`, `Detection Circle 220`.
- **Exports:** `move_speed 68 detection 220 lose 320 attack_range 22 attack_damage1 attack_cooldown1.1 attack_duration0.45 max_health3 wander_speed18`.
- **AI:** `IDLE` wander `wander_speed` 70% idle else `randf*TAU` `y*0.5`, `CHASE` if `dist<=220`, steer `to_player+sep*0.6` `sep` push `<28`, `velocity 68`, `>320 → IDLE`, `<=22 && cooldown → ATTACK`; `ATTACK` `await 0.18 active 0.15` `Hitbox`; `HURT 0.25` knock `140`; `DEAD` `collision disabled queue_free 0.6`.
- **Health:** `3` flash `0.04/0.12`, die `modulate 0.7` knock `90`.

---

## 6. Spawner (`scripts/main.gd:167`)

- `enemy_scene preload Enemy.tscn`, `max_enemies 6`, `spawn_interval 2.2`, `arena_size 2400×900` (`main.gd:8`), `SpawnTimer`.
- `_spawn_enemy` ring `side 0..3` at `player ± arena*0.45` + `randf_range ±80/120`, `_margin 40` (reserved). Gated by `PLAYING`. Spawn y clamped to `HORIZON_MIN_Y -70` — never above the ridge.

---

## 7. Main & Flow (`scenes/Main.tscn` / `scripts/main.gd`)

### Scene Tree

```
Main [Node2D] y_sort script=main.gd GameState START/PLAYING/GAME_OVER
├── Ground ColorRect -400,-200→400,200 0.188,0.227,0.2 + GroundGrid lines 0.05
├── Walls StaticBody Top at horizon (y=-100, 2400×16) / Bottom ±458 / Left-Right ±1208 16×900 — nothing walks above the ridge
├── Player instance Player.tscn 0,0 (min y ≈ -92 against Top wall)
├── Player instance Player.tscn 0,0
├── Obstacles Node2D y_sort (jump-over crate/rock/log, `Obstacle.tscn`/`obstacle.gd`, layer 32; HOP mask drops to 1 to clear them)
├── Enemies Node2D y_sort
├── SpawnTimer 2.2 one_shot false
├── CanvasLayer
│   ├── HUD Control anchors15
│   │   ├── HealthLabel ♥/♡ 1.0→1.0  -220,12→-12,32
│   │   ├── WaveLabel centered -160,12→160,32
│   │   ├── InfoLabel bottom "Arrows/WASD • SPACE hop • X/Z attack"
│   │   └── Title "BLUE BERRY — shell v0.1" 14,12→200,30
│   ├── StartScreen instance StartScreen.tscn (visible on START)
│   └── GameOverScreen instance GameOverScreen.tscn (visible on GAME_OVER)
└── Decor Tree1/Tree2 ColorRect 0.25,0.4,0.25 at -140
```

### StartScreen (`scenes/StartScreen.tscn` / `scripts/start_screen.gd`)

`Control anchors15 640×360` `BG ColorRect 0.137,0.137,0.21,0.92 mouse_filter IGNORE` → `Center CenterContainer anchors15` → `VBox sep16` `Icon 96×96 icon.svg` `Title 42 blue` `Subtitle pink 14` `Divider 260×2 0.12` `Controls 11` `StartButton 220×44 ▶ START` `Hint 10` `QuitButton 140×28 flat` `Version 9`. Script `signal start_game` `PROCESS_MODE_ALWAYS` `_input+_unhandled_input → _try_handle_start` `hop/attack/ui_accept/ENTER/SPACE` → `_on_start_pressed` emit.

### GameOverScreen (`scenes/GameOverScreen.tscn` / `scripts/game_over_screen.gd`)

`Control anchors15` `BG 0.165,0.137,0.137,0.88 IGNORE` → `Center` → `VBox sep14` `Title GAME OVER 36 red` `Subtitle` `ScoreLabel Wave • Kills 16` `Divider` `HBox` `RestartButton 160×44 ↻ RESTART` `MenuButton 140×44`. Script `signals restart_game/menu_game` `PROCESS_MODE_ALWAYS` `show_game_over(wave,kills)` grab focus + pop tween `0.92→1.0 0.22`, `_input` `hop/attack/ui_accept/R → restart`, `ESC → menu`.

### HUD & Draw

`_update_hud:219` `Wave/Kills/Enemies` PLAYING, `Press START` START, `DEAD` GAME_OVER. `_draw:230` arena rect `player - arena*0.5` `0.06` when PLAYING.

---

## 8. Run / Debug

- Launch `godot --path <repo>` → splash → `StartScreen` (per-OS paths in `MEMORY.md` §1).
- VS Code `Launch Project (F5)` type `godot` `port 6007`, main scene set in `project.godot`.
- Headless `--headless --quit --verbose` must show 0 WARNING.

---

## 9. Roadmap (see PLAN.md)

Priority 1: Rabbit sheet, 3-hit combo, blueberry pickup, SFX hitstop, parallax. Priority 2: TileMap level, nav, boss. Priority 3: Gamepad, mobile.

---

## 10. Tuning Checklist

If sluggish → `player.gd:10 move_speed 150`; hop short → `hop_distance 80`; sticky enemy → `attack_cooldown 1.4` or `move_speed 55`; whiff → `AttackHitbox 32×20`.

---

*Source of truth — update on every mechanic change + bump shell v0.2.*
