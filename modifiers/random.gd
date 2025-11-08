extends Modifier
class_name RandomModifier

##DEPRECATED

@export_range(0, 100) var mod_chance := 100

func _init() -> void:
	if block:
		if RNG.randi(0, 100) >= mod_chance:
			var avail_mods := ShopBoard._get_avail_mods(null)
			var mod_ranges := ShopBoard._get_ranges(avail_mods)
			var new_mod: Modifier = RNG.pick_random_weight(mod_ranges, avail_mods)
			
			block.modifier = new_mod
			block.modifier.block = block
	else:
		push_error("NO BLOCK")
