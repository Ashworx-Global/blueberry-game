extends StaticBody2D
# Obstacle — jump-over crate/rock/log for hop mechanic  scripts/obstacle.gd:1
# Collision on layer 32 (value 32, bit 6) — player mask includes 32 normally, but during HOP mask removes it
# Visual picks random type; collision sized to base. y_sort via parent Main y_sort.
# Discovery hook: obstacles stay static, future map reveal can modulate.

@export var type: String = "random" # crate | rock | log | random
@export var allow_random: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var shadow: ColorRect = $Shadow

var _picked: String = ""

func _ready() -> void:
	add_to_group("obstacle")
	collision_layer = 32 # obstacle layer (bit 6)
	collision_mask = 0
	# y_sort: top of sprite is higher than base, but collision at base controls sorting via y
	# parent Main has y_sort_enabled true, so this node's y decides draw order
	if type == "random" and allow_random:
		var r := randi() % 3
		_picked = ["crate", "rock", "log"][r]
	else:
		_picked = type
	_apply_type(_picked)

func _apply_type(t: String) -> void:
	var tex: Texture2D = null
	var col_size := Vector2(32, 10)
	var sprite_offset := Vector2(0, -6)
	match t:
		"crate":
			tex = load("res://assets/sprites/crate.png") as Texture2D
			col_size = Vector2(44, 12)
			sprite_offset = Vector2(0, -10)
		"rock":
			tex = load("res://assets/sprites/rock.png") as Texture2D
			col_size = Vector2(36, 10)
			sprite_offset = Vector2(0, -7)
		"log":
			tex = load("res://assets/sprites/log.png") as Texture2D
			col_size = Vector2(52, 8)
			sprite_offset = Vector2(0, -2)
		_:
			tex = load("res://assets/sprites/crate.png") as Texture2D
	if sprite:
		sprite.texture = tex
		sprite.centered = true
		sprite.offset = sprite_offset
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if collision and collision.shape is RectangleShape2D:
		(collision.shape as RectangleShape2D).size = col_size
		# collision at base (feet)
		collision.position = Vector2(0, col_size.y * 0.5 - 2)
	if shadow:
		shadow.size = Vector2(col_size.x + 6, 6)
		shadow.position = Vector2(-shadow.size.x * 0.5, -2)

# helper for editor preview
func _get_picked() -> String:
	return _picked
