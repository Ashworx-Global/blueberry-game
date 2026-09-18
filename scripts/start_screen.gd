extends Control
# Start splash — shows on launch, emits to Main to begin play.  scripts/start_screen.gd:1
signal start_game

@onready var start_button: Button = $Center/VBox/StartButton
@onready var quit_button: Button = $Center/VBox/QuitButton

func _ready() -> void:
	visible = true
	# focus for gamepad/keyboard
	if start_button:
		start_button.grab_focus()
		if not start_button.pressed.is_connected(_on_start_pressed):
			start_button.pressed.connect(_on_start_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)
	# always process — must handle input even when tree not paused (START state uses DISABLED player, not pause)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	_try_handle_start(event)

func _unhandled_input(event: InputEvent) -> void:
	_try_handle_start(event)

func _try_handle_start(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("hop") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		_on_start_pressed()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		_on_start_pressed()
		get_viewport().set_input_as_handled()

func _on_start_pressed() -> void:
	print("StartScreen: start pressed -> emitting start_game")
	start_game.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()
