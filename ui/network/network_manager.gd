extends Control

const PORT: int = 7000
const DEFAULT_IP: String = "127.0.0.1"
const MAX_CLIENTS: int = 4

@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton

func _ready() -> void:
	_connect_ui_signals()
	_connect_multiplayer_signals()

func _connect_ui_signals() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)

func _connect_multiplayer_signals() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	# SERVER ONLY: Listen for clients connecting to spawn their player characters
	multiplayer.peer_connected.connect(_on_peer_connected)

func _on_host_pressed() -> void:
	_apply_fallback_session_state()
	_initialize_network_server()

func _on_join_pressed() -> void:
	_apply_fallback_session_state()
	_initialize_network_client()

func _initialize_network_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS)
	
	if error != OK:
		print("Failed to host server. Error code: ", error)
		return
		
	NetworkConfig.peer = peer
	multiplayer.multiplayer_peer = peer
	print("Server hosted successfully. Loading world...")
	
	# The Host changes scenes instantly because they own the server environment
	_transition_to_game_world()

func _initialize_network_client() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(DEFAULT_IP, PORT)
	
	if error != OK:
		print("Failed to initiate client connection. Error code: ", error)
		return
		
	NetworkConfig.peer = peer
	multiplayer.multiplayer_peer = peer
	print("Connecting to host at ", DEFAULT_IP, ":", PORT, "...")
	# 🛑 DO NOT transition here. Wait for the server to reply!

func _on_connected_to_server() -> void:
	print("Connected to host successfully. Joining session...")
	# Client transitions now that the handshake is secure
	_transition_to_game_world()

func _on_connection_failed() -> void:
	print("Connection attempt failed.")
	NetworkConfig.clear_connection()
	multiplayer.multiplayer_peer = null

func _on_peer_connected(id: int) -> void:
	print("Server detected peer connected with ID: ", id)
	# This is where your world level script will spawn the new player scene instance.

func _apply_fallback_session_state() -> void:
	if HubWorldMusic.has_method("set_player_class"):
		HubWorldMusic.set_player_class("knight")
	else:
		HubWorldMusic.player_class = "knight"

func _transition_to_game_world() -> void:
	var scene_path := "res://core/levels/hub_world.tscn"
	get_tree().change_scene_to_file(scene_path)
