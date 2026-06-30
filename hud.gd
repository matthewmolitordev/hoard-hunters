extends CanvasLayer

@onready var hp_bar: TextureProgressBar = $TopRightContainer/VBoxContainer/HPBar
@onready var gem_label: Label = $TopRightContainer/VBoxContainer/HPBar/GemCounterContainer/GemLabel

@onready var slot_1: TextureRect = $BottomCenterContainer/ActionBar/Slot1
@onready var total_gems: float = GameManager.total_loot_collected


func _ready() -> void:
	# Initialize display matching global counts on startup
	update_hp(100)
	update_gems(0, GameManager.total_loot_collected)

func update_hp(new_hp: float) -> void:
	hp_bar.value = new_hp

func update_gems(current_level_gems: int, total_game_gems: int) -> void:
	# Formats text cleanly as: "Gems: 4 (Total: 25)"
	gem_label.text = ": %d / %d" % [current_level_gems, total_gems]
