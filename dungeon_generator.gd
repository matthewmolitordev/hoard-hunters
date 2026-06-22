extends Node3D

#preload brick scene to instantiate in loop
const TILE_SCENE = preload("res://tile.tscn")

#placeholder enemy
const SENTRY_SCENE = preload("res://sentry.tscn")

@export var map_size: int = 2000    #grid boundry
@export var absolute_seed: int = 674567
@export var tile_spacing: float = 2.0      #2x2 tile size

var grid = {}     #has map dictionary to track occupied coordinate states {Vector2: bool}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_dungeon()
	
func generate_dungeon() -> void:
	seed(absolute_seed)
	
	var current_pos = Vector2(0,0)
	grid[current_pos] = true
	spawn_tile(current_pos)
	
	# walker algorithm loop: carve out 40 connected spaces
	for i in range(map_size):
		#pick random direction and step
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT]
		var random_direction = directions[randi() % directions.size()]
		current_pos += random_direction
		
		#check if already exists then spawn tile
		if not grid.has(current_pos):
			grid[current_pos] = true
			spawn_tile(current_pos)
			
			if current_pos != Vector2.ZERO and randf() <0.05:
					spawn_element(SENTRY_SCENE,current_pos,3)
			
func spawn_tile(grid_pos: Vector2) -> void:
	var tile_instance = TILE_SCENE.instantiate()
	add_child(tile_instance)
	
	#map 2D grid to 3d 
	tile_instance.position = Vector3(grid_pos.x * tile_spacing, 0, grid_pos.y * tile_spacing)
	
func spawn_element(scene_resource: PackedScene, grid_pos: Vector2, elevation: float) -> void:
	var instance = scene_resource.instantiate()
	add_child(instance)
	
	#map 2D grid to 3d 
	instance.position = Vector3(grid_pos.x * tile_spacing, elevation, grid_pos.y * tile_spacing)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
