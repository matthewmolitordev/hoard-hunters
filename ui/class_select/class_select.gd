extends Control

@onready var knight_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/KnightButton
@onready var acrobat_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/AcrobatButton
@onready var sorcerer_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/SorcererButton

func _ready() -> void:
	_connect_ui_signals()
	knight_button.grab_focus()

func _connect_ui_signals() -> void:
	knight_button.pressed.connect(_on_class_selected.bind("knight"))
	acrobat_button.pressed.connect(_on_class_selected.bind("acrobat"))
	sorcerer_button.pressed.connect(_on_class_selected.bind("sorcerer"))

func _on_class_selected(chosen_class: String) -> void:
	print("ClassSelectUI: Class selected -> ", chosen_class)
	
	HubWorldMusic.player_class = chosen_class
	
	_navigate_to_game_world()

func _navigate_to_game_world() -> void:
	var destination_scene = "res://core/levels/hub_world.tscn"
	
	if ResourceLoader.exists(destination_scene):
		get_tree().change_scene_to_file(destination_scene)
	else:
		get_tree().change_scene_to_file(destination_scene)
