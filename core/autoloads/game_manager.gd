extends Node

signal loot_count_changed(current_gems: int, total_loot: int)

var current_level_gems: int = 0
var total_loot_collected: int = 0

func add_loot(amount: int = 1) -> void:
	_update_loot_state(amount)
	_dispatch_loot_update()

func reset_level_loot() -> void:
	current_level_gems = 0
	_dispatch_loot_update()

func _update_loot_state(amount: int) -> void:
	current_level_gems += amount
	total_loot_collected += amount

func _dispatch_loot_update() -> void:
	loot_count_changed.emit(current_level_gems, total_loot_collected)
