extends AbilityActive
class_name MakeStraight

func trigger() -> bool:
	game.board.spawn_polymino(load("res://polymino_shapes/straight.tres"))
	return true

func _init(gme: GameMain) -> void:
	super(gme)
	
	display_name = "Give Straight"
	description = "Replaces your current polymino with a straight."
	image_path = "res://abils/active/icons/gen_abil.png"
	sp_cost = 16
