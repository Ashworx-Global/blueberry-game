extends CharacterBody2D
# Player — Rabbit hero (beat 'em up shell)  scripts/player.gd:1
# Controls: Arrows/WASD move, Space hop (i-frame dodge), X/Z attack (mob swipe)

signal health_changed(new_health: int, max_health: int)
signal died

enum State { IDLE, RUN, HOP, ATTACK, HURT, DEAD }

@export var move_speed: float = 130.0
@export var hop_distance: float = 64.0
@export var hop_duration: float = 0.28
@export var hop_cooldown: float = 0.45
@export var hop_iframes: float = 0.22
@export var max_health: int = 5
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.18
@export var hurt_iframe_duration: float = 0.8
@export var hurt_stun_duration: float = 0.35

var health: int
var facing: int = 1  # 1 = right, -1 = left
var state: State = State.IDLE

# timers (counts down)
var hop_cooldown_timer: float = 0.0
var hop_timer: float = 0.0
var hop_iframe_timer: float = 0.0
var attack_timer: float = 0.0  # active window remaining
var attack_cooldown_timer: float = 0.0
var hurt_timer: float = 0.0
var hurt_iframe_timer: float = 0.0

var hop_dir: Vector2 = Vector2.RIGHT
var attack_hit_enemies: Array = []  # to ensure one hit per swing

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

func _ready() -> void:
	health = max_health
	add_to_group("player")
	attack_hitbox.monitoring = false
	attack_shape.disabled = true
	# connect hurtbox and attack hitbox if not via scene signal
	if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	if not attack_hitbox.area_entered.is_connected(_on_attack_hitbox_area_entered):
		attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	_update_facing_visual()
	_play_anim("idle")

func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	match state:
		State.DEAD:
			velocity = Vector2.ZERO
			move_and_slide()
			return
		State.HURT:
			# knockback already set in velocity, friction
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			move_and_slide()
			if hurt_timer <= 0.0:
				if is_zero_approx(velocity.length()):
					state = State.IDLE
					_play_anim("idle")
				else:
					state = State.IDLE
			return
		State.HOP:
			hop_timer -= delta
			# constant velocity during hop
			# velocity already set at hop start
			move_and_slide()
			# flicker during iframes
			sprite.visible = true
			if hop_iframe_timer > 0.0:
				sprite.visible = int(Time.get_ticks_msec() / 60.0) % 2 == 0
			if hop_timer <= 0.0:
				velocity = velocity * 0.2  # retain slight momentum
				state = State.IDLE
				sprite.visible = true
				_update_facing_visual()
				_play_anim("idle")
			return
		State.ATTACK:
			attack_timer -= delta
			# allow tiny movement (15%) but mostly rooted
			var inp := _get_move_input()
			velocity = inp * move_speed * 0.15
			move_and_slide()
			# deactivate hitbox after active window (~0.12s)
			# attack_timer starts at 0.36 (windup+active+recovery) — active is middle
			if attack_timer <= 0.16: # recovery ended, deactivate if still on
				_set_attack_active(false)
			if attack_timer <= 0.0:
				state = State.IDLE
				_set_attack_active(false)
				attack_cooldown_timer = attack_cooldown
			return

	# --- IDLE / RUN (free movement) ---
	var input_vec := _get_move_input()

	# facing update
	if input_vec.x != 0:
		facing = 1 if input_vec.x > 0 else -1
		_update_facing_visual()

	# hop input (buffered: just pressed)
	if Input.is_action_just_pressed("hop") and hop_cooldown_timer <= 0.0:
		_start_hop(input_vec)
		return

	# attack input
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		_start_attack()
		return

	# movement
	if input_vec != Vector2.ZERO:
		velocity = input_vec * move_speed
		if state != State.RUN:
			state = State.RUN
			_play_anim("run")
	else:
		velocity = Vector2.ZERO
		if state != State.IDLE:
			state = State.IDLE
			_play_anim("idle")

	move_and_slide()

	# hurt iframes visual
	if hurt_iframe_timer > 0.0:
		sprite.modulate.a = 0.5 if int(Time.get_ticks_msec() / 80.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

func _tick_timers(delta: float) -> void:
	if hop_cooldown_timer > 0.0: hop_cooldown_timer -= delta
	if hop_iframe_timer > 0.0: hop_iframe_timer -= delta
	if attack_cooldown_timer > 0.0: attack_cooldown_timer -= delta
	if hurt_timer > 0.0: hurt_timer -= delta
	if hurt_iframe_timer > 0.0: hurt_iframe_timer -= delta

func _get_move_input() -> Vector2:
	var x := Input.get_axis("move_left", "move_right")
	var y := Input.get_axis("move_up", "move_down")
	var v := Vector2(x, y)
	if v.length() > 1.0:
		v = v.normalized()
	return v

func _update_facing_visual() -> void:
	sprite.scale.x = abs(sprite.scale.x) * facing
	# mirror attack offset
	attack_hitbox.position.x = abs(attack_hitbox.position.x) * facing

func _play_anim(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _start_hop(input_vec: Vector2) -> void:
	# direction = input or facing
	if input_vec != Vector2.ZERO:
		hop_dir = input_vec.normalized()
	else:
		hop_dir = Vector2(facing, 0)
	state = State.HOP
	hop_timer = hop_duration
	hop_iframe_timer = hop_iframes
	hop_cooldown_timer = hop_cooldown + hop_duration
	velocity = hop_dir * (hop_distance / hop_duration)
	_play_anim("hop")
	# hurtbox invulnerability (deferred to avoid flush error)
	hurtbox.set_deferred("monitoring", false)
	# re-enable after iframes via timer check in process
	# use async re-enable
	await get_tree().create_timer(hop_iframes).timeout
	if state == State.HOP or hop_iframe_timer <= 0.0:
		hurtbox.set_deferred("monitoring", true)
	# ensure re-enabled if hop already ended
	if hop_timer <= 0.0:
		hurtbox.set_deferred("monitoring", true)

func _start_attack() -> void:
	state = State.ATTACK
	attack_timer = 0.08 + 0.12 + 0.16  # windup + active + recovery
	attack_hit_enemies.clear()
	_play_anim("attack")
	# windup then activate
	await get_tree().create_timer(0.08).timeout
	if state == State.ATTACK:
		_set_attack_active(true)
		# active window 0.12s
		await get_tree().create_timer(0.12).timeout
		if state == State.ATTACK:
			_set_attack_active(false)

func _set_attack_active(active: bool) -> void:
	attack_hitbox.set_deferred("monitoring", active)
	attack_shape.set_deferred("disabled", not active)
	attack_hitbox.visible = active  # debug visual if needed

func take_damage(amount: int, from_pos: Vector2) -> void:
	if state == State.DEAD: return
	if hurt_iframe_timer > 0.0: return
	if hop_iframe_timer > 0.0: return

	health -= amount
	health = max(health, 0)
	health_changed.emit(health, max_health)

	if health <= 0:
		_die()
		return

	# hurt state
	state = State.HURT
	hurt_timer = hurt_stun_duration
	hurt_iframe_timer = hurt_iframe_duration
	_play_anim("hurt")
	# knockback away from attacker
	var dir := (global_position - from_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2(-facing, -0.3)
	velocity = dir * 180.0
	# flash
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.4, 0.4), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)

func _die() -> void:
	state = State.DEAD
	_play_anim("hurt")
	velocity = Vector2.ZERO
	hurtbox.set_deferred("monitoring", false)
	collision.set_deferred("disabled", true)
	died.emit()
	# simple respawn hook: you could reload scene
	sprite.modulate = Color(1, 1, 1, 0.6)

# signals

func _on_hurtbox_area_entered(area: Area2D) -> void:
	# enemy attack hitboxes are on layer 5, they call take_damage directly via parent
	# This is fallback if enemy uses area directly
	if area.is_in_group("enemy_attack"):
		var dmg := 1
		if area.has_meta("damage"):
			dmg = area.get_meta("damage")
		take_damage(dmg, area.global_position)

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy in attack_hit_enemies:
			return
		attack_hit_enemies.append(enemy)
		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage, global_position)
		# hitstop micro
		Engine.time_scale = 0.08
		await get_tree().create_timer(0.05, true, false, true).timeout
		Engine.time_scale = 1.0
