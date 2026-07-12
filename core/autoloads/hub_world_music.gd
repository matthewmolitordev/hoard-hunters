extends AudioStreamPlayer

var player_class: String = "None"

func _ready() -> void:
	_initialize_audio_state()

func set_player_class(chosen_class: String) -> void:
	player_class = chosen_class

func _initialize_audio_state() -> void:
	if not playing:
		play()
