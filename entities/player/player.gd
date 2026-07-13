extends CharacterBody3D

enum State { NORMAL, KNOCKBACK, DIALOGUE }

@onready var fireball_spell: Node = $Spells/FireballSpell
const FIREBALL_SCENE := preload("res://entities/player/kits/spells/sorcerer/fireball_spell.gd")
const FIREBALL_EXPLOSION_SCENE := preload("res://entities/player/kits/spells/sorcerer/fireball_explosion.tscn")
const LIGHTNING_SCENE := preload("res://entities/player/kits/spells/sorcerer/lightning_bolt.tscn")

@export_group("Movement Properties")
@export var default_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var coyote_duration: float = 0.15 
@export var mouse_sensitivity: float = 0.003
@export var push_force: float = 50.0

@export_group("Combat & Stats")
@export var max_hp: float = 100.0
@export var fire_ball_cooldown: float = 0.3
@export var knockback_duration: float = 0.4
@export var knockback_friction: float = 8.0

@export_group("Gravity Sphere")
@export var GRAVITY_SPHERE_SCENE: PackedScene = preload("res://entities/player/kits/spells/sorcerer/gravity_sphere.tscn")
@export var default_hold_distance: float = 8.0
@export var scroll_speed: float = 1.0
@export var min_distance: float = 2.0 
@export var max_distance: float = 30.0
@export var sphere_move_speed: float = 10.0

@export_group("Lightning Settings")
@export var lightning_max_range: float = 60.0
@export var lightning_beam_thickness: float = 0.3

var current_hp: float = 100.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var time_since_on_floor: float = 0.0
var camera_look_input: float = 0.0
var active_hold_distance: float = 8.0

var current_state: State = State.NORMAL
var knockback_timer: float = 0.0
var camera_target_pos: Vector3

var grabbed_body: RigidBody3D = null

var active_kit: Node = null
var current_gravity_sphere: Node3D = null
var current_lightning_instance: Node3D = null

@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var raycast_fireball: RayCast3D = $Camera3D/RayCast3DFireball
@onready var joint: Generic6DOFJoint3D = $Camera3D/Generic6DOFJoint3D
@onready var hand: StaticBody3D = $Camera3D/Hand

func _enter_tree() -> void:
	_configure_network_authority()

func _ready() -> void:
	await get_tree().process_frame
	
	var network_id := name.to_int()
	if network_id == 0:
		network_id = 1
		
	set_multiplayer_authority(network_id)
	
	if has_node("MultiplayerSynchronizer"):
		get_node("MultiplayerSynchronizer").set_multiplayer_authority(network_id)
	
	if not is_multiplayer_authority():
		camera.current = false
		set_process_unhandled_input(false)
		
	_synchronize_session_frame()

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	_handle_lightning_channel()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() or global_position == Vector3.ZERO:
		return
		
	_process_state_machine(delta)
	_update_gravity_sphere_position(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	_process_input_events(event)

func _exit_tree() -> void:
	_stop_lightning_channel()


func _configure_network_authority() -> void:
	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(get_multiplayer_authority())

func _synchronize_session_frame() -> void:
	await get_tree().process_frame
	
	if is_multiplayer_authority():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if camera:
			camera.make_current()
	else:
		if camera:
			camera.current = false
			
	_bind_class_kit()
	current_hp = max_hp

func _bind_class_kit() -> void:
	var chosen_class := HubWorldMusic.player_class
	match chosen_class:
		"knight": active_kit = get_node_or_null("KnightSpells")
		"acrobat": active_kit = get_node_or_null("AcrobatSpells")
		"sorcerer": active_kit = get_node_or_null("SorcererSpells")

func _process_state_machine(delta: float) -> void:
	match current_state:
		State.NORMAL: _process_normal_movement(delta)
		State.KNOCKBACK: _process_knockback_movement(delta)

func _process_normal_movement(delta: float) -> void:
	var speed := default_speed
	if active_kit and "kit_speed" in active_kit:
		speed = active_kit.kit_speed
		
	if active_kit and "kit_jump_velocity" in active_kit:
		jump_velocity = active_kit.kit_jump_velocity

	if is_on_floor():
		time_since_on_floor = 0.0
		if active_kit and active_kit.has_method("reset_abilities"):
			active_kit.reset_abilities()
	else:
		time_since_on_floor += delta
		velocity.y -= gravity * delta
		
	if Input.is_action_just_pressed("ui_accept"):
		if (active_kit and active_kit.has_method("try_jump") and active_kit.try_jump(self)) or time_since_on_floor <= coyote_duration:
			velocity.y = jump_velocity
		
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
	
	move_and_slide()
	
	if global_position.y < -20.0:
		_reset_position()

func _process_knockback_movement(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, knockback_friction * delta)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	move_and_slide()
	knockback_timer -= delta
	if knockback_timer <= 0.0:
		current_state = State.NORMAL

func apply_knockback(force: Vector3) -> void:
	velocity = force
	knockback_timer = knockback_duration
	current_state = State.KNOCKBACK

func _reset_position() -> void:
	velocity = Vector3.ZERO
	global_position = Vector3(0.0, 5.0, 0.0)

# --- Input Handling & Actions ---

func _process_input_events(event: InputEvent) -> void:
	match current_state:
		State.NORMAL: _handle_normal_input(event)
		State.DIALOGUE: _handle_dialogue_input(event)

func _handle_normal_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_mode()
		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	
	if event.is_action_pressed("action_bar_slot_1") and fireball_spell: fireball_spell.cast_pressed()
	if event.is_action_pressed("action_bar_slot_2"): _cast_fireball_explosion()
	if event.is_action_pressed("action_bar_slot_3"): _cast_gravity_sphere()
		
	if is_instance_valid(current_gravity_sphere):
		_handle_sphere_scrolling(event)
		
	if event.is_action_pressed("click"):
		_handle_click_interaction()
	elif event.is_action_released("click"):
		_release_object()
		
	if event.is_action_pressed("right_click"):
		_push_object()

func _handle_dialogue_input(event: InputEvent) -> void:
	var is_confirm: bool = event.is_action_pressed("ui_accept")
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	
	if is_confirm or is_click:
		get_viewport().set_input_as_handled()
		_end_dialogue()

func _toggle_mouse_mode() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _handle_sphere_scrolling(event: InputEvent) -> void:
	if event.is_action_pressed("wheel_up"):
		active_hold_distance = clamp(active_hold_distance + scroll_speed, min_distance, max_distance)
		get_viewport().set_input_as_handled() 
	elif event.is_action_pressed("wheel_down"):
		active_hold_distance = clamp(active_hold_distance - scroll_speed, min_distance, max_distance)
		get_viewport().set_input_as_handled()

func _handle_click_interaction() -> void:
	if not raycast.is_colliding():
		return
		
	var target = raycast.get_collider()
	if not target:
		return
		
	if target.has_method("start_dialogue"):
		target.start_dialogue()
	elif target.get_parent().has_method("start_dialogue"):
		target.get_parent().start_dialogue()
	else:
		_try_grab_object(target)

# --- Spells & Combat Mechanics ---
func _cast_fireball_explosion() -> void:
	raycast_fireball.force_raycast_update()
	if not raycast_fireball.is_colliding():
		return
		
	var spawn_point := raycast_fireball.get_collision_point()
	var explosion = FIREBALL_EXPLOSION_SCENE.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = spawn_point

func _cast_gravity_sphere() -> void:
	if is_instance_valid(current_gravity_sphere) or not GRAVITY_SPHERE_SCENE:
		return
		
	raycast_fireball.force_raycast_update()
	if raycast_fireball.is_colliding():
		var hit_point := raycast_fireball.get_collision_point()
		active_hold_distance = clamp(camera.global_position.distance_to(hit_point), min_distance, max_distance)
	else:
		active_hold_distance = default_hold_distance
		
	current_gravity_sphere = GRAVITY_SPHERE_SCENE.instantiate()
	get_parent().add_child(current_gravity_sphere)
	
	var screen_center: Vector2 = Vector2(get_viewport().get_size()) / 2.0
	var ray_origin := camera.project_ray_origin(screen_center)
	var ray_direction := -camera.global_transform.basis.z
	current_gravity_sphere.global_position = ray_origin + (ray_direction * active_hold_distance)

func _update_gravity_sphere_position(delta: float) -> void:
	if not is_instance_valid(current_gravity_sphere):
		return
		
	var screen_center: Vector2 = Vector2(get_viewport().get_size()) / 2.0
	var ray_origin := camera.project_ray_origin(screen_center)
	var ray_direction := -camera.global_transform.basis.z
	var target_position := ray_origin + (ray_direction * active_hold_distance)
	
	current_gravity_sphere.global_position = current_gravity_sphere.global_position.move_toward(
		target_position, 
		sphere_move_speed * delta
	)

func _handle_lightning_channel() -> void:
	if Input.is_action_just_pressed("action_bar_slot_4") and current_lightning_instance == null:
		current_lightning_instance = LIGHTNING_SCENE.instantiate()
		add_child(current_lightning_instance)

	if Input.is_action_pressed("action_bar_slot_4") and is_instance_valid(current_lightning_instance):
		var origin_point: Vector3 = $Muzzle.global_position if has_node("Muzzle") else global_position + Vector3(0.0, 0.9, 0.0)
		var forward_vector := -camera.global_transform.basis.z
		var target_point := camera.global_position + (forward_vector * lightning_max_range)
		
		current_lightning_instance.global_position = origin_point
		current_lightning_instance.global_transform.basis = Basis.IDENTITY
		
		# Resolved fix: Redirected the call interface method name to sync with your lighting_bolt update
		current_lightning_instance.set_target_point(target_point)
		_check_piercing_damage(origin_point, target_point)

	if Input.is_action_just_released("action_bar_slot_4"):
		_stop_lightning_channel()

func _stop_lightning_channel() -> void:
	if is_instance_valid(current_lightning_instance):
		current_lightning_instance.queue_free()
	current_lightning_instance = null

func _check_piercing_damage(start: Vector3, end: Vector3) -> void:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var cylinder := CylinderShape3D.new()
	
	cylinder.radius = lightning_beam_thickness
	cylinder.height = start.distance_to(end)
	query.shape = cylinder
	
	var mid_point := start.lerp(end, 0.5)
	var base_transform := Transform3D(Basis.IDENTITY, mid_point).looking_at(end, Vector3.UP)
	var rotation_fix := Basis(Vector3.RIGHT, deg_to_rad(90.0))
	query.transform = Transform3D(base_transform.basis * rotation_fix, mid_point)
	
	var hits := space_state.intersect_shape(query, 32)
	for hit in hits:
		var hit_object = hit["collider"]
		if hit_object and hit_object.is_in_group("enemy"):
			hit_object.call_deferred("queue_free")

# --- Object Interaction Mechanics ---

func _try_grab_object(target: Node3D) -> void:
	if target is RigidBody3D and not target.freeze:
		grabbed_body = target
		grabbed_body.gravity_scale = 0.0
		joint.node_b = grabbed_body.get_path()

func _release_object() -> void:
	if grabbed_body:
		grabbed_body.gravity_scale = 1.0
		joint.node_b = NodePath("")
		grabbed_body = null

func _push_object() -> void:
	if raycast.is_colliding():
		var target = raycast.get_collider()
		if target is RigidBody3D and not target.freeze:
			var push_direction := -camera.global_transform.basis.z.normalized()
			target.apply_central_impulse(push_direction * push_force)

# --- Stats, Dialogue & System Closures ---

func take_damage(amount: float) -> void:
	current_hp = clamp(current_hp - amount, 0.0, max_hp)
	_update_hud_hp()
	if current_hp <= 0.0:
		_player_die()

func _update_hud_hp() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_health_display"):
		hud.update_health_display(current_hp, max_hp)

func _player_die() -> void:
	print("Player has died!")

func start_dialogue(face_position: Vector3, text: String) -> void:
	current_state = State.DIALOGUE
	velocity = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera_target_pos = face_position
	DialogueUi.show_text(text)

func _end_dialogue() -> void:
	DialogueUi.hide_dialogue()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_state = State.NORMAL
