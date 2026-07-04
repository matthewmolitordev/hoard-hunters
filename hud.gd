extends CanvasLayer

@onready var hp_bar: TextureProgressBar = $TopRightContainer/VBoxContainer/HPBar
@onready var gem_label: Label = $TopRightContainer/VBoxContainer/GemCounterContainer/GemLabel

#@onready var slot_1: TextureRect = $BottomCenterContainer/ActionBar/Slot1
@onready var total_gems: float = GameManager.total_loot_collected


func _ready() -> void:
	update_hp(100)
	update_gems(0, GameManager.total_loot_collected)

func update_hp(new_hp: float) -> void:
	hp_bar.value = new_hp

func update_gems(current_level_gems: int, _total_game_gems: int) -> void:
	gem_label.text = ": %d / %d" % [current_level_gems, total_gems]

func update_health(current: float, max_value: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_value
		hp_bar.value = current
