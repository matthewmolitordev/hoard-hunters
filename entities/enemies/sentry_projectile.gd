extends Area3D

@export var speed: float = 15.0
@export var damage: float = 3.0
@export var knockback_force: float = 15.0

func _ready() -> void:
	_initialize_signals()

func _physics_process(delta: float) -> void:
	_advance_projectile(delta)

func _initialize_signals() -> void:
	body_entered.connect(_on_body_entered)

func _advance_projectile(delta: float) -> void:
	global_position -= global_transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy") or body.is_in_group("enemies"):
		return
		
	_process_impact(body)

func _process_impact(body: Node3D) -> void:
	var knockback_dir := _calculate_knockback_direction(body)
	
	if body.is_in_group("player"):
		_apply_player_effects(body, knockback_dir)
	elif body is RigidBody3D:
		_apply_physics_impulse(body, knockback_dir)

	queue_free()

func _calculate_knockback_direction(body: Node3D) -> Vector3:
	var dir := (body.global_position - global_position).normalized()
	dir.y = 0.25 
	return dir.normalized()

func _apply_player_effects(body: Node3D, knockback_dir: Vector3) -> void:
	if body.has_method("apply_knockback"):
		body.apply_knockback(knockback_dir * knockback_force)
	if body.has_method("take_damage"):
		body.take_damage(damage)

func _apply_physics_impulse(body: RigidBody3D, knockback_dir: Vector3) -> void:
	body.apply_central_impulse(knockback_dir * knockback_force)
