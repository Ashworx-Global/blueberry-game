extends Node2D
# Main — world + spawner + HUD + Start/GameOver flow  scripts/main.gd:1

enum GameState { START, PLAYING, GAME_OVER }

@export var max_enemies: int = 6
@export var spawn_interval: float = 2.2
@export var arena_size: Vector2 = Vector2(2400, 900)
# Walkable top edge: nothing (player, enemy, obstacle) may spawn or rest
# above the horizon line (world y ≈ -90). The Top wall sits at y=-100 to
# enforce it physically; this margin keeps spawns below it.
const HORIZON_MIN_Y := -70.0

@onready var enemies: Node2D = $Enemies
@onready var spawn_timer: Timer = $SpawnTimer
@onready var player: CharacterBody2D = $Player
@onready var hud: Control = $CanvasLayer/HUD
@onready var hud_health: Label = $CanvasLayer/HUD/HealthLabel
@onready var hud_wave: Label = $CanvasLayer/HUD/WaveLabel
@onready var hud_info: Label = $CanvasLayer/HUD/InfoLabel
@onready var start_screen: Control = $CanvasLayer/StartScreen
@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen
@onready var background: Node2D = $Background

var wave: int = 1
var kills: int = 0
var current_state: GameState = GameState.START
var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
var obstacle_scene: PackedScene = preload("res://scenes/Obstacle.tscn")

@export var obstacle_count: int = 14
@onready var obstacles: Node2D = $Obstacles

func _ready() -> void:
	y_sort_enabled = true
	spawn_timer.wait_time = spawn_interval
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	if player:
		if player.has_signal("health_changed") and not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)
		if player.has_signal("died") and not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)

	# wire splash / game over signals (guard if scenes not yet instanced)
	if start_screen and start_screen.has_signal("start_game") and not start_screen.start_game.is_connected(_on_start_game):
		start_screen.start_game.connect(_on_start_game)
	if game_over_screen:
		if game_over_screen.has_signal("restart_game") and not game_over_screen.restart_game.is_connected(_on_restart_game):
			game_over_screen.restart_game.connect(_on_restart_game)
		if game_over_screen.has_signal("menu_game") and not game_over_screen.menu_game.is_connected(_on_menu_game):
			game_over_screen.menu_game.connect(_on_menu_game)

	# wire background discovery — give it player reference for parallax + future fog/discovery
	if background and player:
		if "player" in background:
			background.player = player

	show_start_screen()

func _process(_delta: float) -> void:
	queue_redraw()

# ── Flow ─────────────────────────────────────────────────

func show_start_screen() -> void:
	current_state = GameState.START
	wave = 1
	kills = 0
	spawn_timer.stop()
	# clear any leftover enemies (important after menu without reload)
	for child in enemies.get_children():
		child.queue_free()
	# clear obstacles preview (will respawn on start)
	if obstacles:
		for child in obstacles.get_children():
			child.queue_free()
	if hud:
		hud.visible = false
	if start_screen:
		start_screen.visible = true
		# focus button next frame
		if start_screen.has_node("Center/VBox/StartButton"):
			await get_tree().process_frame
			var btn: Button = start_screen.get_node("Center/VBox/StartButton")
			if btn and start_screen.visible:
				btn.grab_focus()
	if game_over_screen:
		game_over_screen.visible = false
	# freeze player but keep visible behind dim
	if player:
		player.visible = true
		player.process_mode = Node.PROCESS_MODE_DISABLED
		# ensure player reset if coming from win without reload (not needed on first launch — player already fresh)
		if "health" in player and "max_health" in player and player.health <= 0:
			# dead — will be fresh after reload, but if we ever reset in-place, restore
			player.health = player.max_health
			player.state = 0 # IDLE
			player.global_position = Vector2.ZERO
			player.visible = true
	_update_hud()

func start_game() -> void:
	print("Main: start_game() called, state=", current_state)
	if current_state == GameState.PLAYING:
		print("Main: already PLAYING, ignoring")
		return
	current_state = GameState.PLAYING
	print("Main: -> PLAYING, enabling player & spawner")
	if start_screen:
		start_screen.visible = false
	if game_over_screen:
		game_over_screen.visible = false
	if hud:
		hud.visible = true
	# (re)enable player
	if player:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.global_position = Vector2.ZERO
		# hard reset health/state in case we reused scene without reload
		if "health" in player:
			player.health = player.max_health
			_on_player_health_changed(player.health, player.max_health)
		if "state" in player:
			player.state = 0
		if player.has_node("CollisionShape2D"):
			var col: CollisionShape2D = player.get_node("CollisionShape2D")
			col.disabled = false
		if player.has_node("Hurtbox"):
			var hb: Area2D = player.get_node("Hurtbox")
			hb.monitoring = true
		player.visible = true
	# reset counters
	wave = 1
	kills = 0
	for child in enemies.get_children():
		child.queue_free()
	if obstacles:
		for child in obstacles.get_children():
			child.queue_free()
		_spawn_obstacles()
	# spawn initial wave
	for _i in 2:
		_spawn_enemy()
	spawn_timer.start()
	_update_hud()

func show_game_over() -> void:
	if current_state == GameState.GAME_OVER:
		return
	current_state = GameState.GAME_OVER
	spawn_timer.stop()
	if game_over_screen and game_over_screen.has_method("show_game_over"):
		game_over_screen.show_game_over(wave, kills)
	else:
		if game_over_screen:
			game_over_screen.visible = true
	# freeze remaining enemies in place
	for e in enemies.get_children():
		if e is CharacterBody2D:
			(e as CharacterBody2D).velocity = Vector2.ZERO
			e.set_physics_process(false)
	# keep HUD visible dimmed? show wave on HUD already updated to DEAD
	if hud_wave:
		hud_wave.text = "DEAD — Wave %d  Kills %d" % [wave, kills]

func _on_start_game() -> void:
	print("Main: _on_start_game received -> starting game")
	start_game()

func _on_restart_game() -> void:
	# clean reload — guarantees fresh player/enemies and returns to START via _ready
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# ── Spawner & HUD (unchanged but gated by PLAYING) ─────

func _on_spawn_timer_timeout() -> void:
	if current_state != GameState.PLAYING:
		return
	if enemies.get_child_count() >= max_enemies:
		return
	_spawn_enemy()
	if kills > 0 and kills % 8 == 0:
		wave += 1
		_update_hud()

func _spawn_enemy() -> void:
	if player == null or not is_instance_valid(player):
		return
	if current_state != GameState.PLAYING:
		return
	var e: CharacterBody2D = enemy_scene.instantiate()
	var side := randi() % 4
	var pos := Vector2.ZERO
	var _margin := 40.0
	match side:
		0:
			pos = Vector2(player.global_position.x - arena_size.x * 0.45, player.global_position.y + randf_range(-80, 80))
		1:
			pos = Vector2(player.global_position.x + arena_size.x * 0.45, player.global_position.y + randf_range(-80, 80))
		2:
			pos = Vector2(player.global_position.x + randf_range(-120, 120), player.global_position.y - arena_size.y * 0.4)
		3:
			pos = Vector2(player.global_position.x + randf_range(-120, 120), player.global_position.y + arena_size.y * 0.4)
	# never above the horizon line
	pos.y = clampf(pos.y, HORIZON_MIN_Y, arena_size.y * 0.5 - 24.0)
	e.global_position = pos
	enemies.add_child(e)
	if e.has_signal("died"):
		e.died.connect(func(): _on_enemy_died())

func _spawn_obstacles() -> void:
	if obstacles == null or obstacle_scene == null:
		return
	var attempts := 0
	var spawned := 0
	while spawned < obstacle_count and attempts < 120:
		attempts += 1
		var x := randf_range(-arena_size.x * 0.46, arena_size.x * 0.46)
		var y := randf_range(HORIZON_MIN_Y, arena_size.y * 0.42)
		var pos := Vector2(x, y)
		# keep start area clear for fair begin
		if pos.distance_to(Vector2.ZERO) < 140.0:
			continue
		# keep away from walls
		if absf(pos.x) > arena_size.x * 0.5 - 48 or absf(pos.y) > arena_size.y * 0.5 - 24:
			continue
		var too_close := false
		for c in obstacles.get_children():
			if c.global_position.distance_to(pos) < 90.0:
				too_close = true
				break
		if too_close:
			continue
		var o: Node2D = obstacle_scene.instantiate() as Node2D
		o.global_position = pos
		obstacles.add_child(o)
		spawned += 1
	# if we spawned fewer due to constraints, it's okay

func _on_enemy_died() -> void:
	if current_state != GameState.PLAYING:
		return
	kills += 1
	if kills % 6 == 0:
		wave += 1
	_update_hud()

func _on_player_health_changed(new_health: int, max_health: int) -> void:
	if hud_health:
		var hearts := ""
		for i in max_health:
			hearts += "♥" if i < new_health else "♡"
		hud_health.text = "%s  %d/%d" % [hearts, new_health, max_health]

func _on_player_died() -> void:
	show_game_over()

func _input(event: InputEvent) -> void:
	# ESC always quits, R restarts when game over
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if current_state == GameState.GAME_OVER:
			_on_menu_game()
		else:
			get_tree().quit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if current_state == GameState.GAME_OVER:
			_on_restart_game()

func _update_hud() -> void:
	if hud_wave:
		if current_state == GameState.PLAYING:
			hud_wave.text = "Wave %d  Kills %d  Enemies %d/%d" % [wave, kills, enemies.get_child_count(), max_enemies]
		elif current_state == GameState.START:
			hud_wave.text = "Press START"
		elif current_state == GameState.GAME_OVER:
			hud_wave.text = "DEAD — Wave %d  Kills %d" % [wave, kills]
	if hud_info and current_state == GameState.PLAYING:
		hud_info.text = "Arrows/WASD move  •  SPACE hop/jump over crates  •  X/Z attack  •  R restart"

func _draw() -> void:
	if player and current_state == GameState.PLAYING:
		draw_rect(Rect2(player.global_position - arena_size * 0.5, arena_size), Color(1, 1, 1, 0.06), false, 1.0)
