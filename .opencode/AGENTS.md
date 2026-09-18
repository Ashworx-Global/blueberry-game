# Blue Berry — Project Memory

## Project Overview
**Blue Berry** is a pixel-art **Beat 'em Up / Belt-Scroll Brawler** (Golden Axe-like) in **Godot 4.7.2** (GL Compatibility, GDScript only, project root = repo root). Rabbit hops to dodge swarming berries, mob-attack clears space. **Never open parent folder as project; always `--path C:\Dev\BlueBerry`.**

- **Engine:** `4.7.2 stable gl_compatibility` `viewport 640×360 → 1280×720 canvas_items Nearest`
- **Entry:** `run/main_scene="res://scenes/Main.tscn"` (`uid://b1ueb3rry_main`) → `Main Node2D y_sort` owns `StartScreen` + `GameOverScreen` via `CanvasLayer`
- **Pixel:** `default_texture_filter 0` `snap` implied, `2× scale` `AnimatedSprite2D`, `16×24` rabbit placeholder `ColorRect` + `SpriteFrames` `idle/run/hop/attack/hurt`

---

## Repository Structure
```
C:\Dev\BlueBerry\
├── .opencode/AGENTS.md          ← this file (agent memory)
├── SPEC.md                      ← canonical spec (source of truth)
├── GDD.md                       ← high-level pitch
├── MEMORY.md                    ← runbook / error fixes
├── PLAN.md                      ← roadmap (next features)
├── README.md / COPILOT_INSTRUCTIONS.md
├── project.godot                640×360 GL compat, input hop/attack
├── icon.svg (+ .import)         128×128 blueberry rabbit
├── default_env.tres
├── .gitignore / .gitattributes
├── .vscode/ settings.json (godotTools.editorPath) launch.json (type godot port 6007) tasks.json
├── assets/sprites/ + assets/sfx/ (empty — add rabbit.png)
└── scenes/ + scripts/
    ├── Main.tscn / main.gd      (uid://b1ueb3rry_main) y_sort 800×400 arena Walls SpawnTimer HUD Start/GameOver
    ├── StartScreen.tscn / start_screen.gd (uid://b1ueb3rry_startscreen) ALWAYS dim 0.92
    ├── GameOverScreen.tscn / game_over_screen.gd (uid://b1ueb3rry_gameover) ALWAYS pop
    ├── Player.tscn / player.gd  (uid://b1ueb3rry_p1ayer) 130 hop 64/0.28 i-frame 0.22
    └── Enemy.tscn / enemy.gd    (uid://b1ueb3rry_enemy) chase 68 detect 220
```

---

## Scene Hierarchy (verified 2026-08-28)

### `scenes/Main.tscn:1` (uid://b1ueb3rry_main, load_steps 7)
```
Main [Node2D] y_sort script=main.gd GameState START/PLAYING/GAME_OVER
├── Ground ColorRect -400,-200→400,200 0.188,0.227,0.2 + GroundGrid 3 lines
├── Walls StaticBody Top/Bottom 800×16 at -408/408 Left/Right 16×400
├── Player instance Player.tscn 0,0
├── Enemies Node2D y_sort
├── SpawnTimer 2.2
├── CanvasLayer
│   ├── HUD Control anchors15
│   │   ├── HealthLabel ♥/♡ -220,12 → -12,32
│   │   ├── WaveLabel centered -160,12 → 160,32
│   │   ├── InfoLabel bottom
│   │   └── Title "BLUE BERRY — shell v0.1"
│   ├── StartScreen instance StartScreen.tscn (ALWAYS, visible START)
│   └── GameOverScreen instance GameOverScreen.tscn (ALWAYS, visible GAME_OVER)
└── Decor Tree1/Tree2
```
`main.gd:25` `_ready` `y_sort` `connect SpawnTimer/player signals/start_screen/game_over` → `show_start_screen`.

### `scenes/StartScreen.tscn:1` (uid://b1ueb3rry_startscreen, load_steps 3)
```
StartScreen [Control] anchors15 script=start_screen.gd ALWAYS
├── BG ColorRect anchors15 0.137,0.137,0.21,0.92 mouse_filter IGNORE
└── Center CenterContainer anchors15
    └── VBox sep16 center
        ├── Icon 96×96 icon.svg
        ├── Title 42 blue
        ├── Subtitle pink 14
        ├── Divider 260×2 0.12
        ├── Controls 11
        ├── StartButton 220×44 ▶ START
        ├── Hint 10
        └── QuitButton 140×28 flat
```
`start_screen.gd:20` ` _input+_unhandled_input → _try_handle_start` `hop/attack/ui_accept/SPACE/ENTER` emit `start_game`.

### `scenes/GameOverScreen.tscn:1` (uid://b1ueb3rry_gameover)
```
GameOverScreen [Control] anchors15 script=game_over_screen.gd ALWAYS
├── BG ColorRect anchors15 0.165,0.137,0.137,0.88 IGNORE
└── Center → VBox sep14
    ├── Title GAME OVER 36 red
    ├── ScoreLabel Wave 1 • Kills 0 16
    ├── Divider 260×2
    └── HBox sep12
        ├── RestartButton 160×44
        └── MenuButton 140×44
```
`show_game_over(wave,kills)` grab focus + pop tween.

### `scenes/Player.tscn:1` (uid://b1ueb3rry_p1ayer, load_steps 6)
```
Player [CharacterBody2D] groups player
├── CollisionShape2D 14×20 at 0,-6
├── AnimatedSprite2D 0,-12 scale2 SpriteFrames idle/run/hop/attack/hurt + ColorRect placeholder
│   └── Placeholder Body/Ears/Eyes
├── Hurtbox Area2D layer2 mask16 → 14×20
├── AttackHitbox Area2D layer4 mask8 28×18 at 16,-10
└── Camera2D smoothing 6 drag 0.15 current
```

### `scenes/Enemy.tscn:1` (uid://b1ueb3rry_enemy, load_steps 7)
```
Enemy [CharacterBody2D] groups enemy
├── Collision 14×18 at 0,-7
├── AnimatedSprite2D 0,-12 scale2 SpriteFrames idle/run/attack/hurt + ColorRect green
├── Hurtbox layer8 mask4 14×18
├── Hitbox layer16 mask2 22×14 at 14,-9
└── Detection Circle 220
```

---

## Scripts — Behavior Contracts

### `scripts/main.gd:1` `GameState START/PLAYING/GAME_OVER`
- `_ready:25` `show_start_screen:53` `START` stop timer clear enemies hide HUD show splash `player DISABLED`.
- `start_game:86` `PLAYING` hide splash show HUD `player INHERIT` reset health/state pos0, `wave1 kills0` clear enemies spawn2 start timer.
- `show_game_over:124` `GAME_OVER` stop timer `game_over.show_game_over` freeze enemies.
- Spawns ring `randi%4` `arena*0.45` `±80/120`, max6.
- Signals: `start_screen.start_game → _on_start_game → start_game`, `game_over.restart/menu → reload_current_scene`.

### `scripts/player.gd:1` `State 6`
- `SPEED130 HOP64/0.28 COOLDOWN0.45 IFRAME0.22 MAX5 ATTACK1 COOLDOWN0.18`.
- `_physics_process` state match; `_play_anim(anim_name:166)`; `_start_hop:170` `dir*(64/0.28)` `set_deferred monitoring false→true`; `_start_attack:193` `await 0.08→active 0.12`; `_set_attack_active:207` `set_deferred`; `take_damage:212` `hurt 0.35 i-frame0.8` `die:240` `DEAD` deferred.

### `scripts/enemy.gd:1` `State 5`
- `move68 detect220 lose320 attack22 cooldown1.1 duration0.45 max3 wander18`.
- `_physics_process:55` `IDLE wander → CHASE if dist<=220 → ATTACK if <=22` steer `+sep*0.6`; `_start_attack:140` `await0.18 active0.15`; `set_deferred` hitbox.

### `scripts/start_screen.gd:1` / `game_over_screen.gd:1`
- `ALWAYS` `visible` toggle, `signal start/restart/menu`, `_input + _unhandled_input` for keyboard, `grab_focus`, `Background modulate` tweens.

---

## Input & Layers

`move_* A/W/S/D Arrows Joy` `hop Space Joy0` `attack X/Z Joy2` + `ui_accept`.
Layers: `1 world` `2 player_hurt` `4 player_attack` `8 enemy_hurt` `16 enemy_attack`; masks `4↔8`, `16↔2`.

---

## How to Run / Debug (see MEMORY.md)

- **Play:** `Gadot --path C:\Dev\BlueBerry` or F5 `Launch Project`
- **Import:** `Gadot --headless --path . --import`
- **Fixes:** header ordering `ext→sub→node`, `anim_name`, `60.0`, `_margin`, `set_deferred`, `WHEN_PAUSED→ALWAYS`, `mouse_filter IGNORE`.

---

## Conventions for Agents

- Project root = repo root; always `--path C:\Dev\BlueBerry`.
- One script per scene; signals over direct fetch; `get_node_or_null` + null guards.
- Never `ext_resource` after `sub_resource`; `load_steps = ext+sub`.
- `set_deferred("monitoring",…)` inside physics flush.
- UI that must work while gameplay frozen → `PROCESS_MODE_ALWAYS`; gameplay freeze via `DISABLED` not `paused`.
- Verify `Godot --headless --quit → 0 WARNING` before commit.
- Prefer editing existing file over creating new; never commit `.godot/`.

---

*Agent memory — update when SPEC.md/MEMORY.md hierarchy changes.*
