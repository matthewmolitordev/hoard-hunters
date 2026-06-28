extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/QuitButton

func _ready() -> void:
	# Connect the button click signals to our functions
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.grab_focus()
	
	# Check if the music is already playing so it doesn't restart
	if not HubWorldMusic.playing:
		HubWorldMusic.play()

func _on_start_pressed() -> void:
	# Replace this path with the actual path to your main dungeon scene file
	get_tree().change_scene_to_file("res://class_select.tscn")

func _on_quit_pressed() -> void:
	# Safely closes the game application
	get_tree().quit()
