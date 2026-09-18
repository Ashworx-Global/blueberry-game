extends CharacterBody2D
# Enemy — basic chaser (seeks player)  scripts/enemy.gd:1
# Simple 3-state AI: IDLE -> CHASE -> ATTACK, with HURT/DEAD

signal died

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

@export var move_speed: float = 68.0
@export var detection_range: float = 220.0
@export var lose_range: float = 320.0
@export var attack_range: float = 22.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.1
@export var attack_duration: float = 0.45
@export var max_health: int = 3
@export var wander_speed: float = 18.0

var health: int
var state: State = State.IDLE
var attack_cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var hurt_timer: float = 0.0
var facing: int = 1

var player: Node2D = null
var wander_dir: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var detection_shape: CollisionShape2D = $Detection/CollisionShape2D

func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	hurtbox.add_to_group("enemy_hurtbox")
	hitbox.add_to_group("enemy_attack")
	hitbox.set_meta("damage", attack_damage)
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	_pick_wander_dir()
	# find player (deferred so Main has spawned)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	_play("idle")

func _physics_process(delta: float) -> void:
	if attack_cooldown_timer > 0.0: attack_cooldown_timer -= delta

	# try to re-acquire player if null
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	match state:
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			move_and_slide()
			return
		State.HURT:
			hurt_timer -= delta
			velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)
			move_and_slide()
			if hurt_timer <= 0.0:
				state = State.CHASE if _can_see_player() else State.IDLE
				_play("run" if state == State.CHASE else "idle")
			return
		State.ATTACK:
			attack_timer -= delta
			velocity = Vector2.ZERO
			move_and_slide()
			if attack_timer <= 0.0:
				_set_hitbox_active(false)
				attack_cooldown_timer = attack_cooldown
				state = State.CHASE if _can_see_player() else State.IDLE
				_play("run" if state == State.CHASE else "idle")
			return
		State.IDLE:
			# wander a bit, look for player
			wander_timer -= delta
			if wander_timer <= 0.0:
				_pick_wander_dir()
			if wander_dir != Vector2.ZERO:
				velocity = wander_dir * wander_speed
				_update_facing(velocity.x)
			else:
				velocity = Vector2.ZERO
			move_and_slide()
			if _can_see_player():
				state = State.CHASE
				_play("run")
			return
		State.CHASE:
			if player == null:
				state = State.IDLE
				_play("idle")
				velocity = Vector2.ZERO
				move_and_slide()
				return

			var to_player := player.global_position - global_position
			var dist := to_player.length()

			if dist > lose_range:
				state = State.IDLE
				_play("idle")
				velocity = Vector2.ZERO
				move_and_slide()
				return

			if dist <= attack_range and attack_cooldown_timer <= 0.0:
				_start_attack(to_player)
				return

			# chase steer + separation from other enemies
			var dir := to_player.normalized()
			# separation
			var sep := _separation_vector()
			dir = (dir + sep * 0.6).normalized()

			velocity = dir * move_speed
			_update_facing(velocity.x)
			move_and_slide()
			return

func _can_see_player() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	# distance check; optionally raycast if walls exist
	var d := global_position.distance_to(player.global_position)
	return d <= detection_range

func _start_attack(to_player: Vector2) -> void:
	state = State.ATTACK
	attack_timer = attack_duration
	_update_facing(to_player.x)
	_play("attack")
	velocity = Vector2.ZERO
	# windup then active
	await get_tree().create_timer(0.18).timeout
	if state == State.ATTACK:
		_set_hitbox_active(true)
		await get_tree().create_timer(0.15).timeout
		if state == State.ATTACK:
			_set_hitbox_active(false)

func _set_hitbox_active(active: bool) -> void:
	hitbox.set_deferred("monitoring", active)
	hitbox_shape.set_deferred("disabled", not active)

func _separation_vector() -> Vector2:
	var sep := Vector2.ZERO
	var count := 0
	for other in get_tree().get_nodes_in_group("enemy"):
		if other == self: continue
		if not is_instance_valid(other): continue
		var d := global_position.distance_to(other.global_position)
		if d < 28.0 and d > 0.1:
			sep += (global_position - other.global_position).normalized() / max(d, 1.0)
			count += 1
	if count > 0:
		sep /= float(count)
		if sep.length() > 1.0:
			sep = sep.normalized()
	return sep

func _pick_wander_dir() -> void:
	# 70% idle, 30% wander
	if randf() < 0.7:
		wander_dir = Vector2.ZERO
	else:
		var ang := randf() * TAU
		wander_dir = Vector2(cos(ang), sin(ang) * 0.5).normalized()
	wander_timer = randf_range(1.0, 2.5)

func _update_facing(x_vel: float) -> void:
	if abs(x_vel) > 1.0:
		var new_facing := 1 if x_vel > 0 else -1
		if new_facing != facing:
			facing = new_facing
			sprite.scale.x = abs(sprite.scale.x) * facing
			hitbox.position.x = abs(hitbox.position.x) * facing

func _play(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func take_damage(amount: int, from_pos: Vector2) -> void:
	if state == State.DEAD: return
	health -= amount
	# hit flash
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1, 0.5, 0.5), 0.04)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1), 0.12)

	if health <= 0:
		_die(from_pos)
		return

	state = State.HURT
	hurt_timer = 0.25
	_play("hurt")
	# knockback
	var dir := (global_position - from_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2(-facing, 0)
	velocity = dir * 140.0
	_set_hitbox_active(false)

func _die(from_pos: Vector2) -> void:
	state = State.DEAD
	_play("hurt")
	collision.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	_set_hitbox_active(false)
	died.emit()
	sprite.modulate = Color(1, 1, 1, 0.7)
	# small knock
	var dir := (global_position - from_pos).normalized()
	velocity = dir * 90.0
	await get_tree().create_timer(0.6).timeout
	queue_free()

func _on_hurtbox_area_entered(_area: Area2D) -> void:
	pass # player handles via its hitbox signal

func _on_hitbox_area_entered(area: Area2D) -> void:
	# hit player hurtbox
	if area.is_in_group("player_hurtbox") or area.get_parent().is_in_group("player"):
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(attack_damage, global_position)
