# fireball_explosion.gd
extends Area3D

@export var max_radius: float = 5.0
@export var expansion_speed: float = 0.8 

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var damaged_bodies: Array[Node3D] = []

func _ready() -> void:
	var sphere: SphereShape3D = collision_shape.shape as SphereShape3D
	sphere.radius = 0.01
	mesh_instance.scale = Vector3.ZERO
	
	body_entered.connect(_on_body_entered)
	$GPUParticles3D.emitting = true
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(sphere, "radius", max_radius, expansion_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	tween.tween_property(mesh_instance, "scale", Vector3(max_radius * 2, max_radius * 2, max_radius * 2), expansion_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	await get_tree().create_timer($GPUParticles3D.lifetime).timeout
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	# DEBUG PRINT: This will print the name of ANY physical object the blast touches
	print("EXPLOSION COLLIDED WITH: ", body.name, " (Group enemy?: ", body.is_in_group("enemy"), ")")

	if body.is_in_group("enemy") and not damaged_bodies.has(body):
		damaged_bodies.append(body)
		print("Obliterated: ", body.name)
		body.queue_free()
