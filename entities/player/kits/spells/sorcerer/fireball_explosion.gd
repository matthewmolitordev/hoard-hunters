extends Area3D

@export var max_radius: float = 5.0
@export var expansion_speed: float = 0.8 

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var particles: GPUParticles3D = $GPUParticles3D

var _damaged_bodies: Array[Node3D] = []

func _ready() -> void:
	_initialize_visuals_and_signals()
	_execute_expansion_tweens()
	_listen_for_lifecycle_end()

func _initialize_visuals_and_signals() -> void:
	var sphere: SphereShape3D = collision_shape.shape as SphereShape3D
	sphere.radius = 0.01
	mesh_instance.scale = Vector3.ZERO
	
	body_entered.connect(_on_body_entered)
	particles.emitting = true

func _execute_expansion_tweens() -> void:
	var sphere: SphereShape3D = collision_shape.shape as SphereShape3D
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(sphere, "radius", max_radius, expansion_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	tween.tween_property(mesh_instance, "scale", Vector3.ONE * (max_radius * 2.0), expansion_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func _listen_for_lifecycle_end() -> void:
	get_tree().create_timer(particles.lifetime).timeout.connect(_on_lifetime_expired)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		_process_damage(body)

func _process_damage(body: Node3D) -> void:
	if _damaged_bodies.has(body):
		return
		
	_damaged_bodies.append(body)
	
	if body.has_method("take_damage"):
		body.take_damage()
	else:
		body.queue_free()

func _on_lifetime_expired() -> void:
	queue_free()
