extends StaticBody3D

const COIN_SCENE = preload("res://coin.tscn")
const DIAMOND_SCENE = preload("res://diamond.tscn")
const TOURMALINE_SCENE = preload("res://tourmaline.tscn")

@onready var timer: Timer = $Timer
var is_spawning = true

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer.wait_time = 0.5
	timer.start()

func _input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed():
		is_spawning = !is_spawning
		
	if is_spawning:
		timer.start()
		print("Coin fountain: START")
	else:
		timer.stop()
		print("Coin fountain: STOP")
		

func _on_timer_timeout() -> void:
	for i in range(2):
		spawn_coin()
		spawn_diamond()
		spawn_tourmaline()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func spawn_coin() -> void:
	var new_coin = COIN_SCENE.instantiate() as RigidBody3D
	get_parent().add_child(new_coin)
	var spawn_offset = Vector3(randf_range(-0.4,0.4), 1.0, randf_range(-0.4, 0.4))
	new_coin.global_transform.origin = global_transform.origin + spawn_offset
	
	var force = Vector3(
		randf_range(-0.1, 0.1),
		0,
		randf_range(-0.1, 0.1),
		)
	
	new_coin.apply_central_impulse(force)
	
func spawn_diamond() -> void:
	var new_DIAMOND = DIAMOND_SCENE.instantiate() as RigidBody3D
	get_parent().add_child(new_DIAMOND)
	var spawn_offset = Vector3(randf_range(-0.4,0.4), 1.0, randf_range(-0.4, 0.4))
	new_DIAMOND.global_transform.origin = global_transform.origin + spawn_offset
	
	var force = Vector3(
		randf_range(-0.1, 0.1),
		0,
		randf_range(-0.1, 0.1),
		)
	
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
