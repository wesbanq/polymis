extends AbilityActive
class_name NoAbility

func _init(gme: GameMain) -> void:
	super(gme)
	
	display_name = "None"
	description = "Nothing. Empty. Zero. Void."
	image_path = "res://abils/active/icons/gen_abil.png"
	sp_cost = 0
