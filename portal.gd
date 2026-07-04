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
			
		# === THE FIX: Defer the scene change so the physics loop can finish ===
		get_tree().call_deferred("change_scene_to_file", destination_scene)
		
	else:
		GameManager.add_loot(1)
		# Defer this one too just to be completely safe
		body.call_deferred("queue_free")
		
