extends Node
class_name PlayerSpawnerComponent

@export_group("Setup")
@export var player_scene: PackedScene
@export var spawn_container_path: NodePath

@onready var _spawn_container: Node = get_node_or_null(spawn_container_path) if spawn_container_path else get_parent()

func _ready() -> void:
	if not multiplayer.is_server():
		return
		
	_initialize_spawner_lifecycle()

func _initialize_spawner_lifecycle() -> void:
	_spawn_player_character(1)
	
	for id in multiplayer.get_peers():
		_spawn_player_character(id)
		
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	_spawn_player_character(id)

func _on_peer_disconnected(id: int) -> void:
	_remove_player_character(id)

func _spawn_player_character(id: int) -> void:
	if not _spawn_container:
		push_error("PlayerSpawnerComponent: Execution aborted. Target spawn container node path is invalid.")
		return
		
	if _spawn_container.has_node(str(id)):
		return
		
	var p_instance: Node3D = player_scene.instantiate()
	p_instance.name = str(id)
	
	if _spawn_container is Node3D:
		p_instance.position = _spawn_container.position
		p_instance.rotation = _spawn_container.rotation
		
	p_instance.tree_entered.connect(_configure_authority.bind(p_instance, id))
	
	_spawn_container.add_child.call_deferred(p_instance)
	print("PlayerSpawnerComponent: Replicated entity successfully queued for Peer ID ", id)

func _configure_authority(player_node: Node3D, id: int) -> void:
	player_node.set_multiplayer_authority(id)
	
	if player_node.has_node("MultiplayerSynchronizer"):
		player_node.get_node("MultiplayerSynchronizer").set_multiplayer_authority(id)
		
	if id != multiplayer.get_unique_id():
		if player_node.has_node("Camera3D"):
			var camera = player_node.get_node("Camera3D") as Camera3D
			camera.current = false
		player_node.set_process_unhandled_input(false)

func _remove_player_character(id: int) -> void:
	if not _spawn_container:
		return
		
	var p_instance = _spawn_container.get_node_or_null(str(id))
	if p_instance:
		p_instance.queue_free()
		print("PlayerSpawnerComponent: Safely de-allocated network entity for Peer ID ", id)
