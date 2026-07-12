extends Node

var peer: ENetMultiplayerPeer = null

func has_active_connection() -> bool:
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func clear_connection() -> void:
	if peer:
		peer.close()
	peer = null
