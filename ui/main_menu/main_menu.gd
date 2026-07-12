extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/QuitButton
@onready var multiplayer_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/MultiplayerButton

func _ready() -> void:
	_connect_ui_signals()
	start_button.grab_focus()

func _connect_ui_signals() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)

func _on_start_pressed() -> void:
	_navigate_to_scene("res://ui/class_select/class_select.tscn")

func _on_multiplayer_pressed() -> void:
	_navigate_to_scene("res://network_manager.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _navigate_to_scene(scene_path: String) -> void:
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
