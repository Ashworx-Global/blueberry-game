extends Control
# Game Over — shown on player death, offers restart / menu.  scripts/game_over_screen.gd:1
signal restart_game
signal menu_game

@onready var score_label: Label = $Center/VBox/ScoreLabel
@onready var restart_button: Button = $Center/VBox/HBox/RestartButton
@onready var menu_button: Button = $Center/VBox/HBox/MenuButton

var _wave: int = 1
var _kills: int = 0

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button and not menu_button.pressed.is_connected(_on_menu_pressed):
		menu_button.pressed.connect(_on_menu_pressed)

func show_game_over(wave: int, kills: int) -> void:
	_wave = wave
	_kills = kills
	visible = true
	if score_label:
		score_label.text = "Wave %d  •  Kills %d" % [wave, kills]
	if restart_button:
		restart_button.grab_focus()
	# small pop animation
	if has_node("Center/VBox"):
		var vbox: Control = $Center/VBox
		vbox.scale = Vector2(0.92, 0.92)
		vbox.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(vbox, "scale", Vector2(1, 1), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(vbox, "modulate:a", 1.0, 0.18)

func hide_game_over() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	_try_handle_input(event)

func _unhandled_input(event: InputEvent) -> void:
	_try_handle_input(event)

func _try_handle_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("hop") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		_on_restart_pressed()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_on_restart_pressed()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_menu_pressed()

func _on_restart_pressed() -> void:
	restart_game.emit()

func _on_menu_pressed() -> void:
	menu_game.emit()
