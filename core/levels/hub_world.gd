extends Node3D

@export var player_base_scene: PackedScene
@export var spawn_node: Node3D 

func _ready() -> void:
	_initialize_level_dependencies()
	_evaluate_network_environment()

func _initialize_level_dependencies() -> void:
	if spawn_node == null:
		spawn_node = self

func _evaluate_network_environment() -> void:
	if multiplayer.multiplayer_peer == null:
		_spawn_local_player()
		return
		
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	if multiplayer.is_server():
		_spawn_network_player(multiplayer.get_unique_id())
	else:
		_notify_server_of_arrival.rpc_id(1, multiplayer.get_unique_id())

func _spawn_local_player() -> void:
	var player = player_base_scene.instantiate()
	spawn_node.add_child(player)

func _spawn_network_player(id: int) -> void:
	if not multiplayer.is_server():
		return
		
	var player = player_base_scene.instantiate()
	player.name = str(id)
	
	_assign_multiplayer_authorities(player, id)
	spawn_node.add_child(player)
	_configure_player_transform(player)

func _assign_multiplayer_authorities(player: Node, id: int) -> void:
	player.set_multiplayer_authority(id)
	if player.has_node("MultiplayerSynchronizer"):
		player.get_node("MultiplayerSynchronizer").set_multiplayer_authority(id)

func _configure_player_transform(player: Node3D) -> void:
	player.global_position = spawn_node.global_position
	player.global_rotation = spawn_node.global_rotation

@rpc("any_peer", "call_local", "reliable")
func _notify_server_of_arrival(client_id: int) -> void:
	if not multiplayer.is_server():
		return
	if spawn_node.has_node(str(client_id)):
		return
		
	_spawn_network_player(client_id)

func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
		
	var player = spawn_node.get_node_or_null(str(id))
	if player:
		player.queue_free()
