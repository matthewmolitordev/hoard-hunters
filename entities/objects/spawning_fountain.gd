extends StaticBody3D

const COIN_SCENE := preload("res://entities/items/coin.tscn")
const DIAMOND_SCENE := preload("res://entities/items/diamond.tscn")
const TOURMALINE_SCENE := preload("res://entities/items/tourmaline.tscn")

@onready var timer: Timer = $Timer

var is_spawning: bool = true

func _ready() -> void:
	_initialize_timer()

func _input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	_handle_input_interaction(event)

func _initialize_timer() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer.wait_time = 0.5
	timer.start()

func _handle_input_interaction(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed()):
		return
		
	is_spawning = !is_spawning
	_update_spawning_state()

func _update_spawning_state() -> void:
	if is_spawning:
		timer.start()
		print("Coin fountain: START")
	else:
		timer.stop()
		print("Coin fountain: STOP")

func _on_timer_timeout() -> void:
	for i in range(2):
		_instantiate_loot(COIN_SCENE)
		_instantiate_loot(DIAMOND_SCENE)
		_instantiate_loot(TOURMALINE_SCENE)

func _instantiate_loot(loot_scene: PackedScene) -> void:
	if not loot_scene:
		return
		
	var item := loot_scene.instantiate() as RigidBody3D
	if not item:
		return
		
	get_parent().add_child(item)
	
	_configure_loot_physics(item)

func _configure_loot_physics(item: RigidBody3D) -> void:
	var spawn_offset := Vector3(randf_range(-0.4, 0.4), 1.0, randf_range(-0.4, 0.4))
	item.global_position = global_position + spawn_offset
	
	var impulse_vector := Vector3(randf_range(-0.1, 0.1), 0.0, randf_range(-0.1, 0.1))
	item.apply_central_impulse(impulse_vector)
