extends TileMapLayer
# Ground — full-arena tuft meadow (scripts/ground.gd). Tiles pix_tuft.png
# across the arena over the moss Ground underlay; per-cell flip + origin-offset
# variants break up the grid so it reads as scattered grass, not a stamp.
# z_index=-1 (Main.tscn): always under player/obstacles/flora. Deterministic
# layout via SEED — bump for a new meadow.

const SHEET := "res://assets/sprites/forest/pix_tuft.png"
const CELL := 128
const COLS := 38 # 38*64 = 2432 wide, covers walls at ±1208
const ROWS := 10 # 10*64 = 640 tall, covers -108..532 (walls -100..458)
const SEED := 20261008
# [flip_h, flip_v, origin offset]: mirrored + nudged twins of the same tuft
const VARIANTS := [
	[false, false, Vector2i(0, 0)],
	[true, false, Vector2i(-12, 4)],
	[false, false, Vector2i(12, 8)],
	[true, false, Vector2i(4, -12)],
	[false, true, Vector2i(-8, 6)],
	[true, true, Vector2i(8, -4)],
]

func _ready() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(CELL, CELL)
	var src := TileSetAtlasSource.new()
	src.texture = load(SHEET) as Texture2D
	src.texture_region_size = Vector2i(CELL, CELL)
	src.create_tile(Vector2i.ZERO)
	for i in VARIANTS.size():
		if i == 0:
			continue
		var alt_id := src.create_alternative_tile(Vector2i.ZERO)
		var data := src.get_tile_data(Vector2i.ZERO, alt_id)
		data.flip_h = VARIANTS[i][0]
		data.flip_v = VARIANTS[i][1]
		data.texture_origin = VARIANTS[i][2]
	tileset.add_source(src, 0)
	tile_set = tileset
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for gy in ROWS:
		for gx in COLS:
			set_cell(Vector2i(gx, gy), 0, Vector2i.ZERO, rng.randi() % VARIANTS.size())
