extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.grab_focus()
	
	if not HubWorldMusic.playing:
		HubWorldMusic.play()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://class_select.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
