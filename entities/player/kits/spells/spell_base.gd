extends Node
class_name SpellBase

@export var spell_name: String = "Spell"

var player: CharacterBody3D
var camera: Camera3D

func _ready() -> void:
	player = get_owner() as CharacterBody3D
	if player:
		await player.ready
		camera = player.get_node_or_null("Camera3D")

func cast_pressed() -> void:
	pass

func cast_held(delta: float) -> void:
	pass

func cast_released() -> void:
	pass
