extends SceneTree
# Dev screenshot harness (NOT game code): boots Main and saves showcase
# shots to docs/showcase/. Run from the repo root:
#   Godot --path . --resolution 1280x720 -s tools/screenshot.gd
# A window opens briefly while it captures; it quits by itself.
var frame := 0
var main: Node


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	main = packed.instantiate()
	get_root().add_child(main)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 10:
		_snap("res://docs/showcase/shot-title.png")
	if frame == 12:
		main.start_game()
	if frame == 30:
		(main.get_node("Player") as Node2D).global_position = Vector2(150, 60)
	if frame == 160:
		_snap("res://docs/showcase/shot-forest.png")
	if frame == 162:
		(main.get_node("Player") as Node2D).global_position = Vector2(0, -300)
	if frame == 220:
		_snap("res://docs/showcase/shot-sky.png")
	if frame == 222:
		(main.get_node("Player") as Node2D).global_position = Vector2(0, 300)
	if frame == 280:
		_snap("res://docs/showcase/shot-ground.png")
		quit()
	return false


func _snap(path: String) -> void:
	var img: Image = get_root().get_texture().get_image()
	if img == null or img.is_empty():
		printerr("screenshot: empty image for ", path)
		return
	print("screenshot: saved ", path, " err=", img.save_png(path))
