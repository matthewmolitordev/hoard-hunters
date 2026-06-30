extends CharacterBody3D

@onready var animation_player = $GoblinMerchant/AnimationPlayer
@onready var face_marker: Marker3D = $FaceMarker
@export_multiline var dialogue_text: String = "Hello traveler! Watch out for those flying enemies up ahead."


func _ready() -> void:
	animation_player.play("Armature|Idle")
	await get_tree().process_frame

# This is called directly by the player's raycast choice
func start_dialogue() -> void:
	print("hekllo world")
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("start_dialogue"):
		player.start_dialogue(face_marker.global_transform.origin, dialogue_text)
