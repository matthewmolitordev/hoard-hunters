extends Node3D

func _ready() -> void:
	if HubWorldMusic.playing:
		HubWorldMusic.stop()


func _process(delta: float) -> void:
	pass
