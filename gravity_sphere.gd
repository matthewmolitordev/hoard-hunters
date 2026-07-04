
extends Area3D

@export var lifetime: float = 5.0
@export var pull_force: float = 150.0

var active_bodies: Array[Node3D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	get_tree().create_timer(lifetime).timeout.connect(func(): queue_free())

func _physics_process(delta: float) -> void:
	var center: Vector3 = global_position
	
	for body in active_bodies:
		if is_instance_valid(body) and body is RigidBody3D:
			body.linear_velocity.y += 9.8 * delta 
			var direction: Vector3 = center - body.global_position
			var distance: float = direction.length()
	
			if distance > 0.1:
				body.linear_velocity += direction.normalized() * pull_force * delta
				
		elif is_instance_valid(body) and (body.is_in_group("enemy") or body.is_in_group("loot")):
			var direction: Vector3 = center - body.global_position
			
			if direction.length() > 0.2:
				body.global_position += direction.normalized() * (pull_force * 0.5) * delta
				
func _on_body_entered(body: Node3D) -> void:
	if (body.is_in_group("loot") or body.is_in_group("enemy")) and not active_bodies.has(body):
		active_bodies.append(body)

func _on_body_exited(body: Node3D) -> void:
	if active_bodies.has(body):
		active_bodies.erase(body)
