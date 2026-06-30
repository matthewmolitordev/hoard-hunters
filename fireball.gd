extends Area3D

@export var speed: float = 20.0
@export var lifetime: float = 3.0

var velocity:Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	
func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func _on_body_entered(body:Node) -> void: 
	body.queue_free()
	queue_free()
