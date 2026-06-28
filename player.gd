extends CharacterBody3D

@onready var raycast = $Camera3D/RayCast3D
@onready var joint = $Camera3D/Generic6DOFJoint3D
@onready var hand = $Camera3D/Hand
var grabbed_body: RigidBody3D = null

const FIREBALL_SCENE = preload("res://fireball.tscn")
@export var fire_ball_cooldown: float = 0.3
var fireball_can_shoot: bool = true

# exposed variable editable in the inspector panel
@export var default_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var coyote_duration: float = 0.15 
@export var mouse_sensitivity: float = 0.003
@export var push_force: float = 50.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var time_since_on_floor: float = 0.0
var camera_look_input: float = 0.0
var active_kit: Node = null

@onready var camera: Camera3D = $ Camera3D

func _ready() -> void:
	var chosen_class = HubWorldMusic.player_class
	if chosen_class == "knight":
		active_kit = $KnightSpells
	elif chosen_class == "acrobat": 
		active_kit = $AcrobatSpells
	elif chosen_class == "sorcerer":
		active_kit = $SorcererSpells
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _physics_process(delta: float) -> void:
	var speed = default_speed
	if active_kit and "kit_speed" in active_kit:
		speed = active_kit.kit_speed
		
	if active_kit and "kit_jump_velocity" in active_kit:
		jump_velocity = active_kit.kit_jump_velocity
	# track coyote time
	if is_on_floor():
		time_since_on_floor = 0.0
	else:
		time_since_on_floor += delta
		
	#apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		active_kit.reset_abilities()
		
	# handle jump
	if Input.is_action_just_pressed("ui_accept"):
		if active_kit.try_jump(self) or time_since_on_floor <= coyote_duration:
			print("jump_velocity", jump_velocity)
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
		
	#handle action bar click (fireball)
	if event.is_action_pressed("action_bar_slot_1") and fireball_can_shoot:
		shoot_fireball()
		
	#handle mouse click grab
	if event.is_action_pressed("click"):
		try_grab_object()
	elif event.is_action_released("click"):
		release_object()
		
	#handle push
	if event.is_action_pressed("right_click"):
		push_object()
		
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
	
func try_grab_object() -> void:
	if raycast.is_colliding():
		var target = raycast.get_collider()
		if target is RigidBody3D and not target.freeze:
			grabbed_body = target
		grabbed_body.gravity_scale = 0.0
		joint.node_b = grabbed_body.get_path()
		
func release_object() -> void:
	if grabbed_body:
		grabbed_body.gravity_scale = 1.0
		joint.node_b = NodePath("")
		grabbed_body = null
		
func push_object() -> void:
	if raycast.is_colliding():
		var target = raycast.get_collider()
		if target is RigidBody3D and not target.freeze:
			var push_direction = -camera.global_transform.basis.z.normalized()
			
			# Apply a sudden physical kick to the object's center of mass
			target.apply_central_impulse(push_direction * push_force)
