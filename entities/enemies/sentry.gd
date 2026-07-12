extends CharacterBody3D

@export var speed: float = 2.0
@export var wander_speed: float = 5.0
@export var float_speed: float = 1.0
@export var projectile_scene: PackedScene = preload("res://entities/enemies/sentry_projectile.tscn")

var target_player: CharacterBody3D = null
var target_height: float = 0.0
var state_timer: float = 0.0
var current_platform_y: float = 0.0
var wander_velocity: Vector3 = Vector3.ZERO

@onready var anim_player: AnimationPlayer = $Sketchfab_Scene/AnimationPlayer
@onready var floor_checker: RayCast3D = $RayCast3D
@onready var shoot_timer: Timer = $ShootTimer
@onready var detection_zone: Area3D = $DetectionZone

func _ready() -> void:
	_initialize_state()
	_connect_signals()

func _physics_process(delta: float) -> void:
	_update_timers_and_wander(delta)
	_apply_height_stabilization(delta)
	_process_movement_vectors()
	move_and_slide()

func fire_projectile() -> void:
	if not projectile_scene:
		return
		
	var target_node = target_player if target_player else get_tree().get_first_node_in_group("player")
	if target_node:
		look_at(target_node.global_position, Vector3.UP)
		
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_transform = global_transform

func _initialize_state() -> void:
	current_platform_y = global_position.y
	anim_player.play("Mushroom|Walk")
	_reset_shoot_timer()

func _connect_signals() -> void:
	detection_zone.body_entered.connect(_on_body_entered_detection)
	detection_zone.body_exited.connect(_on_body_exited_detection)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func _update_timers_and_wander(delta: float) -> void:
	if not floor_checker.is_colliding():
		target_height = current_platform_y + randf_range(2.0, 8.0)
		state_timer = randf_range(2.0, 8.0)
		wander_velocity = -wander_velocity
	else:
		state_timer -= delta
		if state_timer <= 0.0:
			_generate_new_wander_angle()

func _generate_new_wander_angle() -> void:
	state_timer = randf_range(2.0, 8.0)
	var random_angle := randf_range(0.0, 2.0 * PI)
	wander_velocity = Vector3(cos(random_angle), 0.0, sin(random_angle)) * wander_speed

func _apply_height_stabilization(delta: float) -> void:
	global_position.y = move_toward(global_position.y, target_height, float_speed * delta)

func _process_movement_vectors() -> void:
	if target_player:
		_track_and_blend_target_movement()
	else:
		velocity.x = wander_velocity.x
		velocity.z = wander_velocity.z

func _track_and_blend_target_movement() -> void:
	var target_direction := (target_player.global_position - global_position).normalized()
	target_direction.y = 0.0
	
	var blended_direction := (target_direction * 0.5 + wander_velocity.normalized() * 0.5).normalized()
	velocity.x = blended_direction.x * speed
	velocity.z = blended_direction.z * speed
	
	var target_look := Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z)
	if global_position.distance_to(target_look) > 1.0:
		look_at(target_look, Vector3.UP)

func _reset_shoot_timer() -> void:
	shoot_timer.wait_time = randf_range(2.0, 6.0)
	shoot_timer.start()

func _on_body_entered_detection(body: Node) -> void:
	if body.is_in_group("player"):
		target_player = body as CharacterBody3D

func _on_body_exited_detection(body: Node) -> void:
	if body == target_player:
		target_player = null

func _on_shoot_timer_timeout() -> void:
	fire_projectile()
	_reset_shoot_timer()
