extends CharacterBody3D

const FIREBALL_SCENE = preload("res://fireball.tscn")
@export var fire_ball_cooldown: float = 0.3
var fireball_can_shoot: bool = true

# exposed variable editable in the inspector panel
@export var speed: float = 3.0
@export var jump_velocity = 4.5
@export var coyote_duration: float = 0.15 
@export var mouse_sensitivity: float = 0.003

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var time_since_on_floor: float = 0.0
var camera_look_input: float = 0.0

@onready var camera: Camera3D = $ Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _physics_process(delta: float) -> void:
	# track coyote time
	if is_on_floor():
		time_since_on_floor = 0.0
	else:
		time_since_on_floor += delta
		
	#apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# handle jump
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or time_since_on_floor <= coyote_duration:
			velocity.y = jump_velocity
		
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
	
	#safety net
	if global_position.y < -20:
		reset_position()
		
func reset_position() -> void:
	velocity = Vector3.ZERO
	global_position = Vector3(0, 5, 0)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	#handle mouse move
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))
		
	#handle mouse click (fireball)
	if event.is_action_pressed("action_bar_slot_1") and fireball_can_shoot:
		shoot_fireball()
		
		
func shoot_fireball() ->void:
	fireball_can_shoot = false
	var fireball = FIREBALL_SCENE.instantiate()
	get_tree().root.add_child(fireball)
	var camera_node = $Camera3D
	var forward_vector = -camera_node.global_transform.basis.z.normalized()
	var spawn_pos = camera_node.global_position
	spawn_pos += forward_vector * 1.5
	spawn_pos.y -= 0.4
	
	fireball.global_position = spawn_pos
	fireball.velocity = forward_vector * fireball.speed
	fireball.look_at(fireball.global_position + forward_vector, Vector3.UP)
	await get_tree().create_timer(fire_ball_cooldown).timeout
	fireball_can_shoot = true
