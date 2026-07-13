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

func _spawn_local_player() -> void:
	var player = player_base_scene.instantiate()
	spawn_node.add_child(player)
