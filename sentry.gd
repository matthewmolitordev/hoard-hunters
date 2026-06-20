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

#y axis collision
@onready var floor_checker: RayCast3D = $RayCast3D

func _ready() -> void:
	$DetectionZone.body_entered.connect(_on_detection_zone_body_entered)
	$DetectionZone.body_exited.connect(_on_detection_zone_body_exited)
	current_platform_y = global_position.y

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
	if body.is_in_group("player"):
		target_player = body
		
		
func _on_detection_zone_body_exited(body: Node) -> void:
	if body == target_player:
		target_player = null
