extends CharacterBody3D

@export var speed: float = 2.0
@export var wander_speed: float = 5.0
@export var float_speed: float = 1.0

var target_player: CharacterBody3D = null

#hover state variables
var target_height: float = 0.0
var state_timer: float = 0.0
var current_platform_y: float = 0.0
var wander_velocity: Vector3 = Vector3.ZERO
@onready var anim_player = $Sketchfab_Scene/AnimationPlayer

#y axis collision
@onready var floor_checker: RayCast3D = $RayCast3D
@export var projectile_scene: PackedScene = preload("res://sentry_projectile.tscn")
@onready var shoot_timer: Timer = $ShootTimer

func _ready() -> void:
	$DetectionZone.body_entered.connect(_on_detection_zone_body_entered)
	$DetectionZone.body_exited.connect(_on_detection_zone_body_exited)
	current_platform_y = global_position.y
	anim_player.play("Mushroom|Walk")
	await get_tree().process_frame
	
	# Manually connect the signal via code to be absolutely sure it's linked
	if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	start_random_shoot_timer()

func _physics_process(delta: float) -> void:
	#floor sensor override
	if not floor_checker.is_colliding():
		target_height = current_platform_y + randf_range(2.0, 8.0)
		state_timer = randf_range(2.0, 8.0)
		wander_velocity = -wander_velocity
	else:
		state_timer -= delta
		if state_timer <= 0.0:
			state_timer = randf_range(2.0, 8.0)
			randf_range(2.0, 8.0)
			var random_angle = randf_range(0, 2 * PI)
			wander_velocity = Vector3(cos(random_angle), 0 , sin(random_angle)) * wander_speed
	# vertical interpolation step
	global_position.y = move_toward(global_position.y, target_height, float_speed * delta)

	if target_player != null:
		var target_direction = (target_player.global_position - global_position).normalized()
		target_direction.y = 0
		var final_direction = (target_direction * 0.5 + wander_velocity.normalized() * 0.5).normalized()
		velocity.x = final_direction.x * speed
		velocity.z = final_direction.z * speed
		
		#look at player
		var target_look = Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z)
		if global_position.distance_to(target_look) > 1:
			look_at(target_look, Vector3.UP)
	else:
		velocity.x = wander_velocity.x
		velocity.z = wander_velocity.z
	move_and_slide()

func _on_detection_zone_body_entered(body: Node) -> void:
	print("woprkinggnsdjhgn")
	if body.is_in_group("player"):
		print("woprkinggnsdjhgn")
		target_player = body
		
		
func _on_detection_zone_body_exited(body: Node) -> void:
	if body == target_player:
		target_player = null
		
func fire_projectile() -> void:
	if not projectile_scene: return
	
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		var target_pos = player.global_transform.origin
		
		look_at(target_pos, Vector3.UP)
	
	var projectile_instance = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile_instance)
	projectile_instance.global_transform = global_transform
	
func start_random_shoot_timer() -> void:
	print("start timer...")
	shoot_timer.wait_time = randf_range(2.0, 6.0)
	shoot_timer.start()

# This function runs every time the Timer finishes countdown
func _on_shoot_timer_timeout() -> void:
	# 1. Fire the projectile
	fire_projectile()
	
	start_random_shoot_timer()
