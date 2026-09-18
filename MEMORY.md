# Blue Berry — Memory / Runbook

> **For humans & AI agents.** How the game boots, runs, and breaks. Last audited `2026-08-28` (Godot 4.7.2, project root = repo root, `StartScreen` + `Main` + `GameOverScreen`).

---

## 1. How to Run

`<repo>` = repo root (`project.godot` lives there). Use `--path <repo>` (or `--path .` from the repo root). Do NOT open the parent folder as project.

| Task | Command |
|------|---------|
| Play | `godot --path <repo>` or VS Code → `Blue Berry: Launch Project (F5)` |
| Editor | `godot --path <repo> -e` |
| Headless import | `godot --headless --path <repo> --import` |
| Verify (no warnings) | `godot --headless --path <repo> --quit --verbose` then filter `WARNING\|ERROR` (`Select-String` on PowerShell, `grep` on macOS/Linux) |
| Check only | `godot --headless --path <repo> --check-only` |

- **Windows example exe:** `C:\Dev\Gadot\Godot_v4.7.2-stable_win64_console.exe` (use the `_console` build for headless output).
- **macOS example exe:** `/Applications/Godot.app/Contents/MacOS/Godot`.

- **Entry:** `project.godot:9` `run/main_scene="res://scenes/Main.tscn"` (`uid://b1ueb3rry_main`) — `Main` `Node2D` owns `StartScreen`/`GameOverScreen` via `CanvasLayer`. Do NOT open parent folder as project.
- **Renderer:** `GL Compatibility` (`project.godot:18`) `textures/canvas_textures/default_texture_filter=0` nearest, `viewport 640×360 → window 1280×720`, `canvas_items` stretch.
- **VS Code:** `.vscode/settings.json:4` `godotTools.editorPath.godot4` → local Godot exe (see §1), `launch.json:5` type `godot` `port 6007`, `tasks.json:5` headless check. Requires `geequlim.godot-tools 2.7.1`.
- After adding/replacing art (sprites, `assets/sfx/`), always run `--import` then verify `*.import` UIDs still match `ext_resource` in `.tscn`.

## 2. Boot Flow (frame 0)

1. Godot loads `scenes/Main.tscn:1` `Main` `Node2D` (`main.gd:1` `uid://b1ueb3rry_main`) — `y_sort_enabled=true`, `Ground` `ColorRect -400,-200→400,200` (`0.188,0.227,0.2`), `GroundGrid` lines, `Walls` `StaticBody2D` `Top/Bottom (-408/408)`, `Enemies` `Node2D` `y_sort`, `SpawnTimer 2.2s`, `CanvasLayer/HUD` + `StartScreen` + `GameOverScreen`.
2. `Main._ready:25` sets `y_sort`, connects `SpawnTimer.timeout`, `player.health_changed/died`, `start_screen.start_game → _on_start_game`, `game_over.restart_game/menu_game`. Then calls `show_start_screen:53`.
3. `show_start_screen` sets `GameState.START`, `wave=1 kills=0`, stops timer, clears `Enemies`, hides `HUD`, shows `StartScreen` (`StartScreen.visible=true`), hides `GameOverScreen`, freezes `Player` `process_mode=DISABLED` (keeps `visible=true` behind dim). Awaits one frame to `grab_focus()` on `StartButton`.
4. `StartScreen._ready:8` (`start_screen.gd:1` `uid://b1ueb3rry_startscreen`) visits `BG` `ColorRect 0.137,0.137,0.21,0.92 mouse_filter=2` + `Center/VBox` (`Icon` `icon.svg` 96×96, `Title BLUE BERRY 42pt`, `Subtitle` pink, `Divider`, `Controls` 11pt, `StartButton 220×44`, `Hint`, `QuitButton`), `process_mode=ALWAYS`, connects `StartButton.pressed → _on_start_pressed` → emits `start_game`.
5. User presses `SPACE/ENTER/hop/attack` (`start_screen.gd:20` `_input` + `_unhandled_input` → `_try_handle_start`) or clicks **START** → `start_game.emit()` → `Main._on_start_game:143` → `start_game:86`.
6. `start_game` sets `PLAYING`, hides `StartScreen`/`GameOverScreen`, shows `HUD`, resets `Player` (`global_position=0,0`, `health=max`, `state=IDLE`, `Collision disabled=false`, `Hurtbox monitoring=true`, `process_mode=INHERIT`), `wave=1 kills=0`, clears `Enemies`, spawns `2` via `_spawn_enemy`, starts `SpawnTimer`, `_update_hud`.
7. `Player._ready:44` (`player.gd:1`) sets `health=max 5`, `group=player`, disables `AttackHitbox`, connects `Hurtbox/AttackHitbox`, `_play_anim("idle")`. `Enemy._ready:37` (`enemy.gd:1`) finds `player` via `group="player"` after one `process_frame`.
8. `_physics_process` starts: Player moves/hops/attacks/takes damage, Enemy IDLE→CHASE→ATTACK, Spawner ticks, HUD `♥` hearts + `Wave/Kills/Enemies`.

## 3. Runtime Loop

- **Player** `scripts/player.gd:57` `State {IDLE,RUN,HOP,ATTACK,HURT,DEAD}`:
  - Input `get_vector(move_left/right/up/down)` normalized `*130` → `move_and_slide`, `facing` flips `scale.x` + `AttackHitbox` offset (`_update_facing_visual:161`). Anims `idle/run/hop/attack/hurt` via `_play_anim(anim_name)` (fixed shadowing `name→anim_name:166`).
  - **Hop** `hop:170` `dir = input or facing`, `state HOP`, `hop_timer 0.28`, `iframes 0.22`, `velocity = dir*(64/0.28)`, `Hurtbox monitoring=false` deferred, `await 0.22 → monitoring=true`, flicker `int(ticks/60.0)%2`.
  - **Attack** `attack:193` `state ATTACK` `timer 0.36` (0.08 windup+0.12 active+0.16 recover), `await 0.08 → _set_attack_active(true)` (`AttackHitbox 28×18` at `16,-10` layer4), `await 0.12 → false`, hit list `attack_hit_enemies`, hitstop `time_scale 0.08 0.05s`.
  - **Damage** `take_damage:212` ignores if `DEAD`/`hurt_iframe`/`hop_iframe`, `health--`, `health_changed`, `state HURT 0.35` `hurt_iframe 0.8` flash tween, knockback `180`; `health<=0 → _die:240` `DEAD` `Hurtbox monitoring=false` deferred `Collision disabled=true` `died`.
- **Enemy** `scripts/enemy.gd:55` `State {IDLE,CHASE,ATTACK,HURT,DEAD}`:
  - `IDLE` wander `wander_speed 18` `±0.5 y` 70% idle; `_can_see_player:133` `dist<=220` → `CHASE`.
  - `CHASE` steer `to_player.normalized + separation*0.6` (`_separation_vector:158` push if `<28`), `velocity 68`, `>320 → IDLE`, `<=22 && cooldown<=0 → _start_attack`.
  - `ATTACK` `attack_duration 0.45` await `0.18 → hitbox active` (`Hitbox 22×14` at `14,-9` layer16) `0.15 → inactive`, `cooldown 1.1`.
  - `HURT 0.25` knock `140`, `DEAD` `collision disabled` `queue_free 0.6`, `died` signal.
- **Spawner** `main.gd:157` `_on_spawn_timer_timeout` if `PLAYING` and `<6` spawns ring `side 0..3` at `player ± arena*0.45` (`_spawn_enemy:167`), `kills%8 → wave++`; `_on_enemy_died:190` `kills++`, `kills%6 → wave++`.
- **HUD** `CanvasLayer/HUD` `HealthLabel  ♥/♡ 5/5` `WaveLabel` `InfoLabel` `Title`. `_update_hud:219` shows `Wave/Kills/Enemies` when PLAYING.
- **GameOver** `show_game_over:124` stops timer, `game_over_screen.show_game_over(wave,kills)` (`game_over_screen.gd:21` sets `ScoreLabel`, grab `RestartButton`, pop tween `0.92→1.0`), freezes enemies `velocity 0 physics false`, HUD `DEAD`. `_input:208` `R`/`SPACE` → `_on_restart_game:146` `reload_current_scene()` (returns to START via `_ready`), `ESC → _on_menu_game`.

## 4. Key Files & UIDs

| File | UID | Note |
|------|-----|------|
| `scenes/Main.tscn` | `uid://b1ueb3rry_main` | `project.godot:9` entry, load_steps 7 |
| `scenes/Player.tscn` | `uid://b1ueb3rry_p1ayer` | ext `2_player` in Main |
| `scenes/Enemy.tscn` | `uid://b1ueb3rry_enemy` | preload `main.gd:23` |
| `scenes/StartScreen.tscn` | `uid://b1ueb3rry_startscreen` | ext `3_start` in Main, icon `2_icon` |
| `scenes/GameOverScreen.tscn` | `uid://b1ueb3rry_gameover` | ext `4_over` in Main |
| `scripts/main.gd` | — | `GameState START/PLAYING/GAME_OVER` |
| `scripts/player.gd` | — | `State 6`, `max_health 5`, `move 130 hop 64/0.28` |
| `scripts/enemy.gd` | — | `detection 220 lose 320 attack 22` |
| `scripts/start_screen.gd` | — | `signal start_game` `ALWAYS` |
| `scripts/game_over_screen.gd` | — | `signals restart/menu` `ALWAYS` |
| `scenes/Obstacle.tscn` | — | jump-over crate/rock/log, `obstacle.gd`, layer 32, group `obstacle` |
| `assets/sprites/crate|rock|log.png` | — | obstacle art, `Nearest`, picked by `obstacle.gd` |
| `blueberry_1.png` | `uid://ddp8fxr6as2ox` | player `SpriteFrames` source (64×64) |
| `scenes/Background.tscn` | `uid://b1ueb3rry_bg` | parallax layers + ground shader mount |
| `scripts/background.gd` | — | period wrap (`SKY 1280/CLOUD 256/FOREST 512`), pinned FG strips |
| `assets/backgrounds/*.png` | — | tileable forest set; edit rules `parallax_spec.md` §10 |
| `icon.svg` | — | `project.godot:11` + StartScreen Icon |

Verify: UID strings in `*.import` vs `ext_resource` in `.tscn` (`Select-String uid` on PowerShell, `grep -h uid *.import` on macOS/Linux).

## 5. Art Pipeline

- **Background layers (procedural bases, 2026-09-18):** `bg_distant_treeline 1280` (period 1280) → `clouds 256` (period 256) → `forest_treeline 512` (period 512) → near trees `fg_trees_left/right 320` tiled across 3000px world bands (factor 0.7, player walks past) → ground shader tile `ground_iso 256` (periods 256 x+y). Scroll rects are `viewport 640 + one period` wide; `background.gd` wraps drift centered via `_centered_wrap()` — never `fposmod(cam*f, rect.size.x)`, it gaps on the long arena; never pin FG strips to the camera, they read as attached to the player.
- **Placeholders:** `Enemy` uses `AnimatedSprite2D` + empty `SpriteFrames` + green `ColorRect` body (`0.35,0.72,0.35`). Player art is wired (`blueberry_1.png`, `ColorRect` fallback kept). Attack/Hit debug `ColorRect` hidden.
- **Swap (enemy next):** Import enemy sheet `Filter Nearest Mipmap Off`, edit `Enemy.tscn:AnimatedSprite2D SpriteFrames` add frames, keep names. Hitboxes `14×18` / `22×14 at 14,-9` may need retune if sprite wider.
- **After art:** `Godot --import` → `.godot/imported/*.ctex` + `*.import` updated. Do NOT edit `*.import` hash manually.
- **Never commit** `.godot/` (`*.ctex/*.md5`) — in `.gitignore`.
- **Hand-edits:** Clip Studio source `assets/backgrounds/blueberry_backgound.clip`; seamless-edge + export rules in `parallax_spec.md` §10.

## 6. Physics Layers Cheat Sheet

| Layer | Name | Used by |
|-------|------|---------|
| 1 | world | `Walls StaticBody` `TileMap` if added, Player `mask 33` (1+32), `1` during HOP |
| 2 | player_hurtbox | `Player/Hurtbox` `layer2 mask16` |
| 4 | player_attack | `Player/AttackHitbox` `layer4 mask8` |
| 8 | enemy_hurtbox | `Enemy/Hurtbox` `layer8 mask4` |
| 16 | enemy_attack | `Enemy/Hitbox` `layer16 mask2` |
| 32 | obstacle | `Obstacle` `StaticBody layer32 mask0`; player body mask `33` drops to `1` during HOP |

Masks must overlap: `player_attack 4 → enemy_hurtbox 8`, `enemy_attack 16 → player_hurtbox 2`.

## 7. Common Errors & Fixes (historical)

| Error | Cause | Fix |
|-------|-------|-----|
| `ERROR Parse Error: Invalid parameter. [Resource file ...Player.tscn:41] ext_resource not found` + `Player vanished` | `.tscn` had `sub_resource` before `ext_resource` or `node shape=SubResource` before definition | Order `[gd_scene] → [ext_resource]* → [sub_resource]* → [node]*`, `load_steps = ext+sub` (fixed Player `3→6`, Enemy `3→7`, Main `5→7`) |
| `The local function parameter "name" is shadowing base Node.name` | `func _play_anim(name:String)` / `func _play(name` shadows `Node.name` | Rename `name → anim_name` (`player.gd:166` `enemy.gd:191`) |
| `Integer division. Decimal part will be discarded.` | `Time.get_ticks_msec() / 60` int/int | Use `60.0`/`80.0` (`player.gd:84` `player.gd:142`) |
| `The local variable "margin" is declared but never used.` | `var margin :=40.0` in `_spawn_enemy` | Prefix `_margin` (`main.gd:59`/`175`) |
| `The local variable "i" never used` | `for i in 2` | `for _i in 2` (`main.gd:34`/`116`) |
| `ERROR Can't change monitoring while flushing queries. Use call_deferred` | `collision.disabled = true` inside `take_damage`/`_die` during `area_entered` physics flush | Use `set_deferred("monitoring",…)` / `set_deferred("disabled",…)` (`player.gd:208` `enemy.gd:154` `player.gd:240`) |
| Game never starts — splash stays | `StartScreen.process_mode = WHEN_PAUSED` but `get_tree().paused=false` → screen never processes input | Change to `PROCESS_MODE_ALWAYS` (`start_screen.gd:18` `game_over_screen.gd:15`) + handle both `_input` + `_unhandled_input` |
| `StartButton` click blocked | `BG ColorRect` `mouse_filter=STOP` covering button | Set `mouse_filter=2 IGNORE` (`StartScreen.tscn:23` `GameOverScreen.tscn:14`) |
| `Enemy.tscn` AttackBox not hitting | Missing `script=enemy.gd` or layers | Keep `script` + `AttackBox layer16 mask1` |

**General fix loop:** `Close Godot → delete .godot → Godot --headless --path . --import → patch ext_resource uids → reopen → Headless --quit → 0 WARNING`.

## 8. Known Stubs / TODO

- `AnimatedSprite2D SpriteFrames` for Enemy still empty — needs slime/bug sheet (`idle/run/attack/hurt`).
- `default_env.tres` solid color only — add `WorldEnvironment` fog/parallax later.
- `assets/sfx/` empty — add hop/attack/hurt wavs. `assets/sprites/` now holds crate/rock/log + backgrounds forest set is done (see §5).
- `CanvasLayer/HUD/InfoLabel` only during PLAYING — splash controls hint duplicated.
- `.godot/` cache ignored — first clone needs `Godot --import`.

## 9. Conventions for Contributors & Agents

- **Project root = repo root** (`project.godot` at repo root); always `--path <repo>` (see §1 for per-OS executable paths).
- GDScript `snake_case` vars/funcs, `PascalCase` nodes, lowercase groups (`"player"`/`"enemy"`), `@onready get_node` + null guards.
- One script per scene; signals (`start_game`, `restart_game`, `died`, `health_changed`) over direct tree walks.
- `.tscn` ordering strict: `gd_scene → ext_resource → sub_resource → node`; `load_steps = count`.
- Never `monitoring=false` then `get_overlapping_bodies()` same frame — use `set_deferred` or query before disable.
- Use `PROCESS_MODE_ALWAYS` for UI that must work while gameplay frozen (splash/gameover); `DISABLED` to freeze Player during START.
- Verify via headless `--quit` output filtered for `WARNING` before commit (see §1).

---

*Runbook from live audit on 2026-08-28 (unified for all agents 2026-09-18). Update when `SPEC.md` or hierarchy changes.*
