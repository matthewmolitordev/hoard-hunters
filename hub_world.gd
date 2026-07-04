extends Node3D

func _ready() -> void:
	if not HubWorldMusic.playing:
		HubWorldMusic.play()
