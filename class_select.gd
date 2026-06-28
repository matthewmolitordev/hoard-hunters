extends Control

@onready var knight_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/KnightButton
@onready var acrobat_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/AcrobatButton
@onready var sorcerer_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/SorcererButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	knight_button.pressed.connect(_on_class_selected.bind("knight"))
	acrobat_button.pressed.connect(_on_class_selected.bind("acrobat"))
	sorcerer_button.pressed.connect(_on_class_selected.bind("sorcerer"))
	knight_button.grab_focus()


func _on_class_selected(chosen_class: String) -> void:
	print("chosen class: ", chosen_class)
	HubWorldMusic.player_class = chosen_class
	get_tree().change_scene_to_file("res://hub_world.tscn")
