extends Node

var current_level_gems: int = 0
var total_loot_collected: int = 0

func add_loot(amount: int = 1) -> void:
	current_level_gems += amount
	total_loot_collected += amount
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_gems(current_level_gems, total_loot_collected)
