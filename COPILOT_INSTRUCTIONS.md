## GitHub Copilot Instructions for Blue Berry (Godot 4.7 / GDScript)

### Recommended VS Code Extensions
- **GitHub Copilot** — code completion
- **Godot Tools (geequlim.godot-tools 2.7.1)** — GDScript LSP, debugging (type `godot` port 6007)
- **Code Spell Checker** — optional

### Project Context
- **Project root = repo root**: `C:\Dev\BlueBerry\project.godot` (entry `res://scenes/Main.tscn`). Always `--path C:\Dev\BlueBerry`.
- **Structure**: `scenes/Main.tscn` (Main y_sort + Walls + Enemies + CanvasLayer HUD/Start/GameOver) + `scenes/Player.tscn` + `Enemy.tscn` + `StartScreen/GameOverScreen.tscn` + `scripts/*.gd`. See `SPEC.md` (canonical) + `MEMORY.md` (runbook) + `.opencode/AGENTS.md`.
- **Conventions**: GDScript `snake_case` vars/funcs, `PascalCase` nodes, lowercase groups `"player"`/`"enemy"`, `@onready` + null guards, one script per scene, signals (`start_game`, `died`, `health_changed`) over direct tree walks.

### How to Use Copilot Effectively
1. Write clear comments with Godot node types/signals: `# Spawn enemy on ring around player: CharacterBody2D + Area2D Hitbox layer16`.
2. Use descriptive names (`hop_iframes`, `attack_cooldown`, `detection_range`) — matches `player.gd:10` / `enemy.gd:9`.
3. Reference `.tscn` ordering: `gd_scene → ext_resource → sub_resource → node`, `load_steps = ext+sub`.
4. For physics, mention layers: `player_attack 4 → enemy_hurtbox 8`.
5. Always `set_deferred("monitoring",…)` inside `area_entered` flush; use `PROCESS_MODE_ALWAYS` for splash/game-over, `DISABLED` to freeze player.
6. Review suggestions, test via `F5` or `Godot --headless --quit`.

### Example Prompt
```gdscript
# Hop dodge: direction = input or facing, set HOP 0.28s, iframes 0.22, velocity dir*(64/0.28), defer Hurtbox monitoring
func _start_hop(input_vec: Vector2) -> void:
```

### Tips
- Mention `Main.GameState START/PLAYING/GAME_OVER` flow when adding features.
- For art, keep `SpriteFrames` names `idle/run/hop/attack/hurt` and `Nearest` filter.
- Verify: `Gadot --headless --path . --import` then `--quit --verbose | Select-String WARNING`.

---
For more, see [Godot Docs](https://docs.godotengine.org/en/4.7) and [Copilot Docs](https://docs.github.com/en/copilot).
