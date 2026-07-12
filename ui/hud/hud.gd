extends CanvasLayer

@onready var hp_bar: TextureProgressBar = $TopRightContainer/VBoxContainer/HPBar
@onready var gem_label: Label = $TopRightContainer/VBoxContainer/GemCounterContainer/GemLabel

func _ready() -> void:
	_connect_state_observers()
	_initialize_ui_display()

func update_health_display(current: float, max_value: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_value
		hp_bar.value = current

func _connect_state_observers() -> void:
	GameManager.loot_count_changed.connect(_on_loot_count_changed)

func _initialize_ui_display() -> void:
	update_health_display(100.0, 100.0)
	_update_gem_label(GameManager.current_level_gems, GameManager.total_loot_collected)

func _update_gem_label(current_level_gems: int, total_gems: int) -> void:
	gem_label.text = ": %d / %d" % [current_level_gems, total_gems]

func _on_loot_count_changed(current_level_gems: int, total_gems: int) -> void:
	_update_gem_label(current_level_gems, total_gems)
