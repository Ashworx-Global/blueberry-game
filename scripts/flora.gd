extends StaticBody2D
# Flora — 2DPIXX forest dressing: decor (no collision) or blocker (layer 1).
# Instanced as a DIRECT child of Main so Main's y_sort orders each prop against
# the Player by y. NOTE: enemies live in $Enemies (origin y≈0), so flora always
# draws over enemies — reads as chasers pushing through bushes, acceptable.
# Art: 128px 2DPIXX cells displayed @0.5 (≈64px). Full-bleed cells (tree_1/2,
# stumps, mounds) render as dirt patches with the feature on top — intended.

@export var mode: String = "decor" # decor | block
@export var art: String = "bush_1"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# art -> [sprite offset (base-aligned, @0.5), blocker collision size]
const ART := {
	"bush_1": [Vector2(0, -17), Vector2.ZERO],
	"bush_2": [Vector2(0, -17), Vector2.ZERO],
	"grass_1": [Vector2(0, -32), Vector2.ZERO],
	"grass_2": [Vector2(0, -32), Vector2.ZERO],
	"tuft": [Vector2(0, -31), Vector2.ZERO],
	"tree_1": [Vector2(0, -32), Vector2(26, 12)],
	"tree_2": [Vector2(0, -32), Vector2(26, 12)],
	"tree_3": [Vector2(0, -24), Vector2(22, 12)],
	"tree_4": [Vector2(0, -24), Vector2(22, 12)],
	"rock": [Vector2(1, -25), Vector2(36, 12)],
}

func _ready() -> void:
	add_to_group("flora")
	var entry: Array = ART.get(art, ART["bush_1"])
	var tex := load("res://assets/sprites/forest/pix_%s.png" % art) as Texture2D
	if sprite:
		sprite.texture = tex
		sprite.centered = true
		sprite.offset = entry[0]
		sprite.scale = Vector2(0.5, 0.5)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# cosmetic variety only: mirror + slight size jitter (decor only,
		# so blocker collision never desyncs from the sprite)
		sprite.flip_h = randf() < 0.5
		if mode != "block":
			var j := randf_range(0.9, 1.1)
			sprite.scale *= j
	if mode == "block":
		collision_layer = 1 # same as Walls: blocks player AND enemies (no hop-clear)
		collision_mask = 0
		var col_size: Vector2 = entry[1]
		if collision and collision.shape is RectangleShape2D:
			(collision.shape as RectangleShape2D).size = col_size
			collision.position = Vector2(0, col_size.y * 0.5 - 2) # at base (feet)
			collision.disabled = false
	else:
		collision_layer = 0 # inert: scanned by nothing, scans nothing
		collision_mask = 0
		if collision:
			collision.disabled = true
