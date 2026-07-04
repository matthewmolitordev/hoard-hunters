extends CharacterBody3D

@onready var raycast = $Camera3D/RayCast3D
@onready var raycast_fireball = $Camera3D/RayCast3DFireball
@onready var joint = $Camera3D/Generic6DOFJoint3D
@onready var hand = $Camera3D/Hand
var grabbed_body: RigidBody3D = null
var camera_target_pos: Vector3

const FIREBALL_SCENE = preload("res://fireball.tscn")
const FIREBALL_EXPLOSION_SCENE = preload("res://fireball_explosion.tscn")
const LIGHTNING_SCENE = preload("res://lightning_bolt.tscn")

@export var fire_ball_cooldown: float = 0.3
var fireball_can_shoot: bool = true
var fireball_explosion_can_shoot: bool = true

@export var default_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var coyote_duration: float = 0.15 
@export var mouse_sensitivity: float = 0.003
@export var push_force: float = 50.0

@export var max_hp: float = 100.0
var current_hp: float = 100.

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var time_since_on_floor: float = 0.0
var camera_look_input: float = 0.0
var active_kit: Node = null

# Knockback - damage
enum State { NORMAL, KNOCKBACK, DIALOGUE }
var current_state: State = State.NORMAL
var knockback_timer: float = 0.0
@export var knockback_duration: float = 0.4 # How long the player is helpless (in seconds)
@export var knockback_friction: float = 8.0 # How fast they slow down during knockback

@onready var camera: Camera3D = $ Camera3D

@export var GRAVITY_SPHERE_SCENE: PackedScene = load("res://gravity_sphere.tscn")
@export var default_hold_distance: float = 8.0
@export var scroll_speed: float = 1.0 # How many units the sphere moves per scroll click
@export var min_distance: float = 2.0  # Prevent pulling the sphere inside your head
@export var max_distance: float = 30.0 # Maximum range you can push the sphere away
@export var sphere_move_speed: float = 10.0 # Maximum units per second it can travel

var current_gravity_sphere: Node3D = null
var active_hold_distance: float = 8.0 # This tracks the dynamic distance of gravity sphere

@export var lightning_max_range: float = 60.0
@export var lightning_beam_thickness: float = 0.3 # Width of the damage beam

var current_lightning_instance: Node3D = null

func _process(delta: float) -> void:
	handle_lightning_continuous()
	
func _ready() -> void:
	var chosen_class = HubWorldMusic.player_class
	if chosen_class == "knight":
		active_kit = $KnightSpells
	elif chosen_class == "acrobat": 
		active_kit = $AcrobatSpells
	elif chosen_class == "sorcerer":
		active_kit = $SorcererSpells
		
	current_hp = max_hp
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _physics_process(delta: float) -> void:
	match current_state:
		State.NORMAL:
			process_normal_movement(delta)
			
		State.KNOCKBACK:
			process_knockback_movement(delta)
	
	if is_instance_valid(current_gravity_sphere):
		var screen_center = get_viewport().get_size() / 2
		
		var ray_origin = camera.project_ray_origin(screen_center)
		var ray_direction = camera.project_ray_normal(screen_center)
		
		var target_position = ray_origin + (ray_direction * active_hold_distance)
		
		current_gravity_sphere.global_position = current_gravity_sphere.global_position.move_toward(
			target_position, 
			sphere_move_speed * delta
		)
			
func process_normal_movement(delta: float) -> void:
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
	
	if global_position.y < -20:
		reset_position()
		
func reset_position() -> void:
	velocity = Vector3.ZERO
	global_position = Vector3(0, 5, 0)
	
func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.NORMAL:
		if event.is_action_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))
			

		if event.is_action_pressed("action_bar_slot_1") and fireball_can_shoot:
			shoot_fireball()

		if event.is_action_pressed("action_bar_slot_2") and fireball_can_shoot:
			cast_fireball_explosion()
			
		if event.is_action_pressed("action_bar_slot_3") and fireball_can_shoot:
			cast_gravity_sphere()
			
		#if event.is_action_pressed("action_bar_slot_4") and fireball_can_shoot:
			#cast_lightning_spell()
			#handle_lightning_continuous()
			
		if is_instance_valid(current_gravity_sphere):
			if event.is_action_pressed("wheel_up"):
				active_hold_distance = clamp(active_hold_distance + scroll_speed, min_distance, max_distance)
				get_viewport().set_input_as_handled() 
			elif event.is_action_pressed("wheel_down"):
				active_hold_distance = clamp(active_hold_distance - scroll_speed, min_distance, max_distance)
				get_viewport().set_input_as_handled()
			
		if event.is_action_pressed("click"):
			if raycast.is_colliding():
				var target = raycast.get_collider()
				if target.has_method("start_dialogue"):
					target.start_dialogue()
				elif target.get_parent().has_method("start_dialogue"):
					target.get_parent().start_dialogue()
				else:
					try_grab_object()
		elif event.is_action_released("click"):
			release_object()
			
		if event.is_action_pressed("right_click"):
			push_object()
	elif current_state == State.DIALOGUE:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			get_viewport().set_input_as_handled()
			end_dialogue()
		
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
			target.apply_central_impulse(push_direction * push_force)
			
func process_knockback_movement(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, knockback_friction * delta)
	velocity.z = move_toward(velocity.z, 0, knockback_friction * delta)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	move_and_slide()
	knockback_timer -= delta
	if knockback_timer <= 0.0:
		current_state = State.NORMAL

func apply_knockback(force: Vector3) -> void:
	velocity = force
	knockback_timer = knockback_duration
	current_state = State.KNOCKBACK
	
func start_dialogue(face_position: Vector3, text: String) -> void:
	current_state = State.DIALOGUE
	velocity = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera_target_pos = face_position
	DialogueUi.show_text(text)

func end_dialogue() -> void:
	DialogueUi.hide_dialogue()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_state = State.NORMAL

func cast_fireball_explosion() -> void:
	raycast_fireball.force_raycast_update()
	
	if raycast_fireball.is_colliding():
		var hit_collider = raycast_fireball.get_collider()
		
		if hit_collider == null:
			return
			
		var spawn_point: Vector3 = raycast_fireball.get_collision_point()
		
		var explosion = FIREBALL_EXPLOSION_SCENE.instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = spawn_point
	else:
		print("Aiming at empty space or out of range. Fireball Casting aborted.")

	
func take_damage(amount: float) -> void:
	current_hp = clamp(current_hp - amount, 0.0, max_hp)
	update_hud_hp()
	
	if current_hp <= 0.0:
		player_die()

func update_hud_hp() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_health"):
		hud.update_health(current_hp, max_hp)

func player_die() -> void:
	print("Player has died!")
	
func cast_gravity_sphere() -> void:
	if is_instance_valid(current_gravity_sphere):
		return
		
	if GRAVITY_SPHERE_SCENE == null:
		return
		
	raycast_fireball.force_raycast_update()
	if raycast_fireball.is_colliding():
		var hit_point = raycast_fireball.get_collision_point()
		active_hold_distance = camera.global_position.distance_to(hit_point)
		active_hold_distance = clamp(active_hold_distance, min_distance, max_distance)
	else:
		active_hold_distance = default_hold_distance
		
	current_gravity_sphere = GRAVITY_SPHERE_SCENE.instantiate()
	
	var screen_center = get_viewport().get_size() / 2
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_direction = camera.project_ray_normal(screen_center)
	
	var initial_target = ray_origin + (ray_direction * active_hold_distance)
	get_parent().add_child(current_gravity_sphere)
	current_gravity_sphere.global_position = initial_target

func cast_lightning_spell() -> void:
	var origin_point: Vector3 = global_position + Vector3(0, 0.5, 0)
	var target_point: Vector3 = Vector3.ZERO
	if has_node("Muzzle"):
		origin_point = $Muzzle.global_position
	raycast_fireball.force_raycast_update()
	
	if raycast_fireball.is_colliding() and raycast_fireball.get_collision_point() != Vector3.ZERO:
		target_point = raycast_fireball.get_collision_point()
		var hit_object = raycast_fireball.get_collider()
		if hit_object and hit_object.is_in_group("enemy"):
			hit_object.queue_free()
			# if hit_object.has_method("disintegrate"):
			#     hit_object.disintegrate()
	else:
		if camera:
			var forward_vector = -camera.global_transform.basis.z
			target_point = camera.global_position + (forward_vector * 30.0)
		else:
			target_point = origin_point + Vector3(0, 0, -30.0)
	
	if origin_point == Vector3.ZERO or target_point == Vector3.ZERO:
		if target_point == Vector3.ZERO:
			target_point = origin_point + Vector3(0, 0, -5.0)

	fire_lightning_visual(origin_point, target_point)
	

func fire_lightning_visual(from_pos: Vector3, to_pos: Vector3) -> void:
	var bolt = LIGHTNING_SCENE.instantiate()
	var tween = create_tween()
	add_child(bolt)
	bolt.global_position = from_pos
	bolt.global_transform.basis = Basis.IDENTITY 
	bolt.set_points(from_pos, to_pos)
	tween.tween_interval(0.5) 
	tween.tween_callback(bolt.queue_free)
	
	
func handle_lightning_continuous() -> void:
	if Input.is_action_just_pressed("action_bar_slot_4"):
		if current_lightning_instance == null:
			current_lightning_instance = LIGHTNING_SCENE.instantiate()
			add_child(current_lightning_instance)

	if Input.is_action_pressed("action_bar_slot_4") and is_instance_valid(current_lightning_instance):
		var origin_point: Vector3 = global_position + Vector3(0, 0.9, 0)
		if has_node("Muzzle"):
			origin_point = $Muzzle.global_position
			
		var camera = get_viewport().get_camera_3d()
		var forward_vector = -camera.global_transform.basis.z
		
		var target_point: Vector3 = camera.global_position + (forward_vector * lightning_max_range)
		
		current_lightning_instance.global_position = origin_point
		current_lightning_instance.global_transform.basis = Basis.IDENTITY
		
		current_lightning_instance.set_points(origin_point, target_point)
		
		check_piercing_damage(origin_point, target_point)

	if Input.is_action_just_released("action_bar_slot_4"):
		stop_lightning_channel()

func stop_lightning_channel() -> void:
	if is_instance_valid(current_lightning_instance):
		current_lightning_instance.queue_free()
	current_lightning_instance = null

func check_piercing_damage(start: Vector3, end: Vector3) -> void:
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsShapeQueryParameters3D.new()
	
	var cylinder = CylinderShape3D.new()
	cylinder.radius = lightning_beam_thickness
	cylinder.height = start.distance_to(end)
	query.shape = cylinder
	
	var mid_point = start.lerp(end, 0.5)
	var base_transform = Transform3D(Basis.IDENTITY, mid_point)
	
	base_transform = base_transform.looking_at(end, Vector3.UP)
	
	var rotation_fix = Basis(Vector3.RIGHT, deg_to_rad(90.0))
	query.transform = Transform3D(base_transform.basis * rotation_fix, mid_point)
	
	var hits = space_state.intersect_shape(query, 32)
	
	for hit in hits:
		var hit_object = hit["collider"]
		if hit_object and hit_object.is_in_group("enemy"):
			hit_object.call_deferred("queue_free")

func _exit_tree() -> void:
	stop_lightning_channel()
