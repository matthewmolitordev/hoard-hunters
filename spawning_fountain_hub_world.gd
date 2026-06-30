extends StaticBody3D
const COIN_SCENE = preload("res://coin.tscn")
const DIAMOND_SCENE = preload("res://diamond.tscn")
const TOURMALINE_SCENE = preload("res://tourmaline.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in GameManager.total_loot_collected:
		spawn_diamond()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func spawn_diamond() -> void:
	var new_DIAMOND = DIAMOND_SCENE.instantiate() as RigidBody3D
	
	# Fix: Wait for the frame tree to stabilize before adding the child
	get_parent().call_deferred("add_child", new_DIAMOND)
	
	# Set position using global_position (cleaner shortcut for global_transform.origin)
	var spawn_offset = Vector3(randf_range(-0.4, 0.4), 1.0, randf_range(-0.4, 0.4))
	new_DIAMOND.global_position = global_position + spawn_offset
	
	# Apply impulse
	var force = Vector3(randf_range(-0.1, 0.1), 0, randf_range(-0.1, 0.1))
	new_DIAMOND.apply_central_impulse(force)
	
func spawn_tourmaline() -> void:
	var NEW_TOURMALINE = TOURMALINE_SCENE.instantiate() as RigidBody3D
	get_parent().add_child(NEW_TOURMALINE)
	var spawn_offset = Vector3(randf_range(-0.4,0.4), 1.0, randf_range(-0.4, 0.4))
	NEW_TOURMALINE.global_transform.origin = global_transform.origin + spawn_offset
	
	var force = Vector3(
		randf_range(-0.1, 0.1),
		0,
		randf_range(-0.1, 0.1),
		)
	
	NEW_TOURMALINE.apply_central_impulse(force)
