extends Area3D

@export var speed: float = 400.0
@export var damage: float = 10.0
@export var knockback_force: float = 15.0

func _physics_process(delta: float) -> void:
	global_transform.origin -= global_transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemies"):
		return
		
	var knockback_dir = (body.global_transform.origin - global_transform.origin).normalized()
	knockback_dir.y = 0.25 
	knockback_dir = knockback_dir.normalized()
	if body.is_in_group("player"):
		if body.has_method("apply_knockback"):
			body.apply_knockback(knockback_dir * knockback_force)
	
	elif body is RigidBody3D:
		body.apply_central_impulse(knockback_dir * knockback_force)

	queue_free()
