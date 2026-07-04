# stylized_lightning.gd
extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

@export var segments: int = 200
@export var displacement: float = 0.2
@export var flicker_speed: float = 0.1 # How fast it switches shapes

var global_target_point: Vector3 = Vector3.ZERO
var timer: float = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if global_target_point == Vector3.ZERO:
		return

	timer += delta
	if timer >= flicker_speed:
		timer = 0.0
		generate_lightning_loop()

func set_points(_start_pos: Vector3, end_pos: Vector3) -> void:
	global_target_point = end_pos
	generate_lightning_loop()

func generate_lightning_loop() -> void:
	var mesh: ImmediateMesh = mesh_instance.mesh as ImmediateMesh
	if mesh == null:
		return
		
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var local_end: Vector3 = to_local(global_target_point)
	var local_start: Vector3 = Vector3.ZERO 
	
	var current_point: Vector3 = local_start
	var full_vector: Vector3 = local_end - local_start
	
	for i in range(1, segments):
		var progress: float = float(i) / float(segments)
		var target_point: Vector3 = local_start + (full_vector * progress)
		var random_offset := Vector3(
			randf_range(-displacement, displacement),
			randf_range(-displacement, displacement),
			randf_range(-displacement, displacement)
		)
		var edge_mask: float = cos(progress * PI)
		target_point += random_offset * edge_mask
		
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(current_point)
		mesh.surface_add_vertex(target_point)
		
		current_point = target_point
		
	mesh.surface_add_vertex(current_point)
	mesh.surface_add_vertex(local_end)
	mesh.surface_end()
