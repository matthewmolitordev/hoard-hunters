extends AudioStreamPlayer

var player_class: String = "None"

func _ready() -> void:
	pass

func _on_class_selected(chosen_class: String) -> void:
	HubWorldMusic.player_class = chosen_class
	get_tree().change_scene_to_file("res://scenes/hub_world.tscn")
