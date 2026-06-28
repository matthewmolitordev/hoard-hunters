extends Node

@export var kit_speed: float = 7 # Light and fast!
@export var kit_jump_velocity: float = 5.5 # Light and fast!
var can_double_jump: bool = true

# The player node will call this when they hit the floor
func reset_abilities() -> void:
	can_double_jump = true

# Returns true if the knight is allowed to jump
func try_jump(player: CharacterBody3D) -> bool:
	if player.is_on_floor():
		return true # Normal ground jump
	elif can_double_jump:
		can_double_jump = false # Consume the double jump
		print("Knight Double Jump Triggered!")
		return true
		
	return false # No jumps left
