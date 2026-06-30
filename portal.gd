extends Area3D

@export_file("*.tscn") var crypt_dungeon_scene: String = "res://dungeon_room_crypt.tscn"
@export_file("*.tscn") var hub_world_scene: String = "res://hub_world.tscn"



func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		GameManager.current_level_gems = 0
		var current_scene_path = get_tree().current_scene.scene_file_path
		var destination_scene: String = ""
		if current_scene_path == crypt_dungeon_scene:
			destination_scene = hub_world_scene
		elif current_scene_path == hub_world_scene:
			destination_scene = crypt_dungeon_scene
		var error = get_tree().change_scene_to_file(destination_scene)
		if error != OK:
			print("Error loading scene: ", error)
	else:
		# Safely call the global singleton tracker
		GameManager.add_loot(1)
		
		# Despawn the object cleanly from the current level physics grid
		body.queue_free()
