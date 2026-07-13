extends Area3D

@export var lifetime: float = 5.0
@export var pull_force: float = 150.0

var _tracked_bodies: Array[Node3D] = []

func _ready() -> void:
	_initialize_lifecycle()

func _physics_process(delta: float) -> void:
	_process_gravitational_forces(delta)

func _initialize_lifecycle() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)

func _process_gravitational_forces(delta: float) -> void:
	var index = _tracked_bodies.size() - 1
	while index >= 0:
		var body = _tracked_bodies[index]
		if not is_instance_valid(body):
			_tracked_bodies.remove_at(index)
			index -= 1
			continue
			
		_apply_force_to_body(body, delta)
		index -= 1

func _apply_force_to_body(body: Node3D, delta: float) -> void:
	var direction: Vector3 = global_position - body.global_position
	var distance: float = direction.length()
	
	if body is RigidBody3D:
		_influence_rigid_body(body, direction, distance, delta)
	elif body.is_in_group("enemy") or body.is_in_group("loot"):
		_influence_kinematic_body(body, direction, distance, delta)

func _influence_rigid_body(body: RigidBody3D, direction: Vector3, distance: float, delta: float) -> void:
	body.linear_velocity.y += 9.8 * delta 
	if distance > 0.1:
		body.linear_velocity += direction.normalized() * pull_force * delta

func _influence_kinematic_body(body: Node3D, direction: Vector3, distance: float, delta: float) -> void:
	if distance > 0.2:
		body.global_position += direction.normalized() * (pull_force * 0.5) * delta

func _on_body_entered(body: Node3D) -> void:
	if not _tracked_bodies.has(body):
		if body.is_in_group("loot") or body.is_in_group("enemy") or body is RigidBody3D:
			_tracked_bodies.append(body)

func _on_body_exited(body: Node3D) -> void:
	_tracked_bodies.erase(body)

func _on_lifetime_expired() -> void:
	queue_free()
