extends Area3D

@export var speed: float = 20.0
@export var lifetime: float = 3.0

var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	_initialize_lifecycle()

func _physics_process(delta: float) -> void:
	_advance_projectile(delta)

func _initialize_lifecycle() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)

func _advance_projectile(delta: float) -> void:
	global_position += velocity * delta

func _on_body_entered(body: Node) -> void:
	_process_impact(body)

func _process_impact(body: Node) -> void:
	if body.has_method("destroy"):
		body.destroy()
	else:
		body.queue_free()
	queue_free()

func _on_lifetime_expired() -> void:
	queue_free()
