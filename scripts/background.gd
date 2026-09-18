extends Node2D
# Background — 90s semi-pixel 2.5D isometric parallax + discovery hook  scripts/background.gd:1
# Layers: sky_mountains (0.12) → clouds (0.18 auto) → forest (0.45) → ground iso shader (1.0 + perspective)
# Discovery: shader uniform discovery_center/radius — call reveal_at(world_pos) as you uncover map
# Continuous: ground shader scroll + parallax layers offset based on camera/player

@export var player: Node2D
@export var auto_scroll: bool = true
@export var auto_speed_x: float = 6.0 # px/s for clouds
@export var parallax_sky: float = 0.08
@export var parallax_clouds: float = 0.14
@export var parallax_forest: float = 0.38
@export var ground_tiling: float = 2.6
@export var ground_horizon: float = 0.38

@onready var sky_rect: TextureRect = $Parallax/SkyMountains
@onready var clouds_rect: TextureRect = $Parallax/Clouds
@onready var forest_rect: TextureRect = $Parallax/Forest
@onready var ground_rect: ColorRect = $GroundIso
var ground_mat: ShaderMaterial

var _scroll: Vector2 = Vector2.ZERO
var _cloud_scroll: float = 0.0
var _discovery_strength: float = 0.0 # 0 = reveal all, 1 = hidden (future)

func _ready() -> void:
	# cache ground material (create instance)
	if ground_rect and ground_rect.material:
		ground_mat = ground_rect.material as ShaderMaterial
		if ground_mat:
			ground_mat = ground_mat.duplicate() as ShaderMaterial
			ground_rect.material = ground_mat
			ground_mat.set_shader_parameter("tiling", ground_tiling)
			ground_mat.set_shader_parameter("horizon", ground_horizon)
			ground_mat.set_shader_parameter("discovery_radius", 0.0)
	# find player if not assigned
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			await get_tree().process_frame
			player = get_tree().get_first_node_in_group("player") as Node2D
	# subtle idle parallax drift
	if auto_scroll and clouds_rect:
		clouds_rect.material = clouds_rect.material # keep
	z_index = -100
	y_sort_enabled = false

func _process(delta: float) -> void:
	var cam_pos: Vector2 = Vector2.ZERO
	if player and is_instance_valid(player):
		# use player position as camera proxy (Camera2D follows player with smoothing)
		cam_pos = player.global_position
		# also try real Camera2D for more accurate
		var cam := _find_camera()
		if cam:
			cam_pos = cam.global_position
	elif has_node("../Player/Camera2D"):
		var cam2: Camera2D = get_node("../Player/Camera2D")
		cam_pos = cam2.global_position

	# Parallax offsets — continuous wrap via fmod
	if sky_rect:
		sky_rect.position.x = -fposmod(cam_pos.x * parallax_sky, sky_rect.size.x)
		# slight y with horizon
		sky_rect.position.y = -fposmod(cam_pos.y * 0.03, 8.0)
	if clouds_rect:
		_cloud_scroll += delta * auto_speed_x
		clouds_rect.position.x = -fposmod(cam_pos.x * parallax_clouds + _cloud_scroll, clouds_rect.size.x)
	if forest_rect:
		forest_rect.position.x = -fposmod(cam_pos.x * parallax_forest, forest_rect.size.x)
		forest_rect.position.y = -fposmod(cam_pos.y * 0.06, 6.0)

	# Ground shader scroll — 1:1 with world plus time drift if discovery
	if ground_mat:
		_scroll.x = fposmod(cam_pos.x * 0.003, 1.0)  # tiling scroll
		_scroll.y = fposmod(cam_pos.y * 0.002, 1.0)
		ground_mat.set_shader_parameter("scroll", _scroll)
		# keep discovery at player screen center (0.5,0.5) for now — reveal all
		# future: set discovery_center to player UV
		# var vp = get_viewport_rect().size
		# var screen = player.get_global_transform_with_canvas().origin / vp
		# ground_mat.set_shader_parameter("discovery_center", screen)
		ground_mat.set_shader_parameter("discovery_radius", _discovery_strength)

func _find_camera() -> Camera2D:
	if player and player.has_node("Camera2D"):
		return player.get_node("Camera2D") as Camera2D
	for c in get_tree().get_nodes_in_group("player"):
		if c is Camera2D:
			return c as Camera2D
	var cams := get_tree().get_nodes_in_group("camera")
	if not cams.is_empty():
		return cams[0] as Camera2D
	# fallback search
	return get_viewport().get_camera_2d()

# Discovery API — call as you uncover world (for future fog/discovery system)
func reveal_at(world_pos: Vector2, radius: float = 0.35) -> void:
	if ground_mat:
		# convert world to uv 0-1 approx (centered at player)
		var vp := get_viewport_rect().size
		# approximate — caller can also set directly via shader_center
		var uv := Vector2(0.5, 0.78) # default horizon center
		if player:
			# simple: use viewport transform
			var screen := (world_pos - _find_camera().global_position) / vp + Vector2(0.5, 0.5)
			uv = screen.clamp(Vector2.ZERO, Vector2.ONE)
		ground_mat.set_shader_parameter("discovery_center", uv)
		ground_mat.set_shader_parameter("discovery_radius", radius)

func set_discovery_hidden(amount: float) -> void:
	_discovery_strength = clamp(amount, 0.0, 1.0)
	if ground_mat:
		ground_mat.set_shader_parameter("discovery_radius", _discovery_strength)

func _on_player_moved(new_pos: Vector2) -> void:
	reveal_at(new_pos, 0.42)
