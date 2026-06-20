extends Area3D

@export_file("*.tscn") var target_dungeon_scene: String = "res://world.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		var error = get_tree().change_scene_to_file(target_dungeon_scene)
		if error != OK:
			print("Error loading scene: ", error)
