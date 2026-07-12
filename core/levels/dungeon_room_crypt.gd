extends Node3D

func _ready() -> void:
	_handle_level_audio_transition()

func _handle_level_audio_transition() -> void:
	if HubWorldMusic.playing:
		HubWorldMusic.stop()
