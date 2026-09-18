# Blue Berry — Game Design Document (Shell v0.1)

## 1. High Concept
**Blue Berry** is a pixel-art **side-scrolling Beat 'em Up / Brawler** (the "Golden Axe" genre — also called *belt-scroll* or *hack-and-slash brawler*). A rabbit hero brawls through hordes of enemies on a 2D plane with depth (X = left/right, Y = depth toward/away from camera + vertical jump/hop).

> Golden Axe = Sega 1989 belt-scroll brawler. You walk left/right + up/down for depth, with a dedicated attack button, jump, and magic. Blue Berry keeps that formula but replaces horse-riding/magic with **hop-dodge mobility** and **mob-type melee**.

**Pillars:** tight pixel feel, readable hitboxes, hop-as-defense, easy to reskin when rabbit art is ready.

## 2. Genre Clarification
- **Genre name:** `Beat 'em Up` / `Belt-Scroll Brawler` (sub-genre of Side-Scroller).
- **Camera:** side view, slight top-down angle. World is flat; Y-sorting gives depth illusion.
- **Structure:** single-screen-to-scrolling arenas → spawner waves → boss (future).
- **Audience:** keyboard-first, gamepad later.

## 3. Core Loop
1. Player spawns in arena.
2. Enemies spawn at edges, `SEEK` player if within `detection_range`.
3. Player kites with arrow keys, uses **hop** (i-frame dodge) to escape encirclement, uses **mob attack** to clear space.
4. Enemies chase → enter `attack_range` → windup → damage.
5. Kill → score + maybe blueberry pickup (future) → next wave.

## 4. Controls (v0.1 Shell)

| Action | Key | Gamepad (future) | Notes |
|--------|-----|------------------|-------|
| Move Left/Right/Up/Down | Arrow Keys + WASD | Left Stick | 8-dir, normalized |
| Hop / Dodge | `Space` | A / Cross | i-frames, cooldown, directional |
| Mob Attack | `X` or `Z` | X / Square | front arc, locks movement briefly |
| Pause | `Esc` / `P` | Start |  |

Input buffering: hop buffered 0.12s, attack buffered 0.1s.

## 5. Player — Rabbit (Placeholder Art)

### 5.1 Stats
- `move_speed = 130 px/s` (tweak 110–150)
- `hop_distance = 64 px`, `hop_duration = 0.28s`, `hop_cooldown = 0.45s`, `hop_iframes = 0.22s`
- `max_health = 5` (hearts visible in HUD later)
- `attack_damage = 1`, `attack_range = 28 px`, `attack_windup = 0.08s`, `attack_active = 0.12s`, `attack_recovery = 0.16s`, `attack_cooldown = 0.18s`
- Facing: flips sprite via `scale.x`, attack hitbox mirrors.

### 5.2 States
`IDLE / RUN / HOP / ATTACK / HURT / DEAD`

- **HOP:** commit direction = last move input or facing; `velocity = hop_vector * (distance/duration)`. Collision stays, but `hurtbox` disabled. Ignores attack input until 80% done. 20% speed retain on landing.
- **ATTACK:** roots movement (can still be nudged 15% speed). Spawns `AttackHitbox` Area2D at `marker_2d` in front. Single hit per swing (track `hit_enemies` array). Future: 3-hit combo if spamming — shell does single for now, combo hook `combo_count` prepared.
- **HURT:** 0.35s stun, `hurt_iframes = 0.8s` flash, knockback 32px away from attacker.

### 5.3 Hitbox / Hurtbox
- `CharacterBody2D` + `CollisionShape2D` (capsule 14x20)
- `Hurtbox: Area2D` (same shape, on player hurt layer) — receives damage.
- `AttackHitbox: Area2D` (Rectangle 28x18 offset +16 x) — only active during ATTACK active frames, on player attack layer.
- Groups: `"player"` to let enemy `seek`.

### 5.4 Visual Hook for Art Swap
- `AnimatedSprite2D` with `SpriteFrames` placeholder: colored rectangles (pink rabbit, ear triangle). Anim names: `idle`, `run`, `hop`, `attack`, `hurt`. All use same placeholder now — swapping to sprite sheet later is just replacing `SpriteFrames` resource.
- Scale: `2x` pixel snap, `texture_filter = Nearest`.

## 6. Enemy — Basic Chaser (Placeholder: Slime/Berry Bug)

### 6.1 Stats
- `move_speed = 68 px/s` (slower than player)
- `detection_range = 220 px` (circle)
- `lose_range = 320 px` (if player escapes far, returns to IDLE patrol)
- `attack_range = 22 px`, `attack_damage = 1`, `attack_cooldown = 1.1s`
- `max_health = 3`
- `patrol_wander_radius = 40 px` (idle micro-move so not static)

### 6.2 AI State Machine
```
IDLE  --(player within detection_range)--> CHASE
CHASE --(distance <= attack_range && can_attack)--> ATTACK
CHASE --(distance > lose_range)--> IDLE
ATTACK --(animation done)--> CHASE
HURT --(timer)--> CHASE
DEAD --(queue free after 0.6s)-->
```

### 6.3 Implementation
- `CharacterBody2D` + `Navigation? No — simple steer: velocity = (player.global_position - global_position).normalized() * speed`. Separates slightly from other enemies via `avoidance` (push away if overlapping).
- Ray not needed for shell; `detection` is distance check (+ line-of-sight hook: `RayCast2D` ready but disabled unless walls added).
- `Hurtbox: Area2D` + `HitFlash` (modulate).
- `AttackHitbox: Area2D` in front, active ~0.15s during ATTACK.
- Groups: `"enemy"`, `"damageable"`.
- Y-sort: parent `Main` has `y_sort_enabled = true`.

### 6.4 Spawn
- `EnemySpawner` (Marker2D array) at screen edges; timer spawns max 6 active, interval 2.5s.

## 7. World & Systems

### 7.1 Resolution & Pixel
- Base viewport `640×360` (16:9, 16px tiles = 40×22 tiles visible)
- Window override `1280×720` (2× integer scale)
- `stretch/mode = canvas_items`, `aspect = keep`, `scale = 1`
- `default_texture_filter = Nearest (0)` → crisp pixels
- `snap_2d_transforms_to_pixel = true`
- `physics/common/physics_ticks_per_second = 60`

### 7.2 Main Scene (`scenes/Main.tscn`)
- `Node2D (y_sort_enabled = true)` root → `TileMapLayer` or `ColorRect` ground + `StaticBody2D` walls (screen bounds 640×360 expanded to 800×400 scroll)
- `Camera2D` on player, `limit_smoothed = true`, `position_smoothing_enabled = true, speed 6`, drag margin 0.15
- `CanvasLayer HUD` → Health, Wave, Debug label
- `Player` instance centered
- `Enemies` Node2D container (for y-sort)
- `EnemySpawner` Timer

### 7.3 Collision Layers
- Layer 1: World
- Layer 2: Player hurtbox
- Layer 3: Player attack
- Layer 4: Enemy hurtbox
- Layer 5: Enemy attack
Masks set so `player_attack` hits `enemy_hurt`, `enemy_attack` hits `player_hurt`.

### 7.4 Roadmap (post-shell)
- [ ] Sprite sheets + Animations (Aseprite import)
- [ ] 3-hit mob combo + hop-cancel
- [ ] Blueberry pickups (heal / score)
- [ ] Parallax forest background
- [ ] Sound SFX + hitstop (0.05s freeze)
- [ ] Gamepad + mobile touch
- [ ] TileMap level 1, screen scroll clamp

## 8. Project Structure
```
BlueBerry/
  project.godot
  icon.svg
  GDD.md
  scenes/
    Main.tscn
    Player.tscn
    Enemy.tscn
  scripts/
    player.gd
    enemy.gd
    main.gd
  assets/
    sprites/  (placeholder, add rabbit.png later)
    sfx/
  README.md
```

## 9. How to Run
1. Open `C:\Dev\BlueBerry\project.godot` in Godot 4.7.
2. Press F5 (Main is `scenes/Main.tscn`).
3. Arrows/WASD move, Space hop, X/Z attack.

## 10. Tuning Checklist for Designer
- If rabbit feels sluggish → raise `move_speed` to 150.
- If hop too short → raise `hop_distance` to 80.
- If enemy too sticky → raise `attack_cooldown` or lower `move_speed` to 55.
- If attack whiffs → increase `AttackHitbox` rectangle to 32×20.
