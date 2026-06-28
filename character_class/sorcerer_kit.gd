extends Node

func reset_abilities() -> void:
	pass # Shaman doesn't need to reset anything

func try_jump(player: CharacterBody3D) -> bool:
	return player.is_on_floor() # Only true if standing on the ground
