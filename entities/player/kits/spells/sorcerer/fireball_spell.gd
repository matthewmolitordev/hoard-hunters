extends SpellBase

const FIREBALL_SCENE := preload("res://entities/player/kits/spells/sorcerer/preloads/fireball.tscn")

@export var cooldown: float = 0.3
var can_shoot: bool = true

func cast_pressed() -> void:
	if not can_shoot:
		return
		
	can_shoot = false
	var fireball = FIREBALL_SCENE.instantiate()
	get_tree().root.add_child(fireball)
	
	var forward_vector := -camera.global_transform.basis.z.normalized()
	var spawn_pos := camera.global_position + (forward_vector * 1.5)
	spawn_pos.y -= 0.4
	
	fireball.global_position = spawn_pos
	fireball.velocity = forward_vector * fireball.speed
	fireball.look_at(fireball.global_position + forward_vector, Vector3.UP)
	
	get_tree().create_timer(cooldown).timeout.connect(func(): can_shoot = true)
	
