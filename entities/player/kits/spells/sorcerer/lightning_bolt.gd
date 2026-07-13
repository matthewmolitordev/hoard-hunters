extends Node3D

@export var segments: int = 200
@export var displacement: float = 0.2
@export var flicker_speed: float = 0.1

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var _global_target_point: Vector3 = Vector3.ZERO
var _flicker_timer: float = 0.0

func _process(delta: float) -> void:
	_process_flicker_lifecycle(delta)

func set_target_point(end_pos: Vector3) -> void:
	_global_target_point = end_pos
	_regenerate_mesh_surface()

func _process_flicker_lifecycle(delta: float) -> void:
	if _global_target_point == Vector3.ZERO:
		return

	_flicker_timer += delta
	if _flicker_timer >= flicker_speed:
		_flicker_timer = 0.0
		_regenerate_mesh_surface()

func _regenerate_mesh_surface() -> void:
	var immediate_mesh: ImmediateMesh = mesh_instance.mesh as ImmediateMesh
	if not immediate_mesh:
		return
		
	_rebuild_mesh_geometry(immediate_mesh)

func _rebuild_mesh_geometry(mesh: ImmediateMesh) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var local_start: Vector3 = Vector3.ZERO 
	var local_end: Vector3 = to_local(_global_target_point)
	var full_vector: Vector3 = local_end - local_start
	var current_point: Vector3 = local_start
	
	for i in range(1, segments):
		var progress: float = float(i) / float(segments)
		var target_point: Vector3 = local_start + (full_vector * progress)
		
		target_point += _calculate_random_displacement()
		
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(current_point)
		mesh.surface_add_vertex(target_point)
		
		current_point = target_point
		
	mesh.surface_add_vertex(current_point)
	mesh.surface_add_vertex(local_end)
	mesh.surface_end()

func _calculate_random_displacement() -> Vector3:
	return Vector3(
		randf_range(-displacement, displacement),
		randf_range(-displacement, displacement),
		randf_range(-displacement, displacement)
	)
