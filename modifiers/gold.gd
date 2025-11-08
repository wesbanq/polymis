extends Modifier
class_name GoldModifier

@export var extra_score: int = 200

var lines_finished: int = 0

func trigger(_who: Variant = null) -> int:
	var neighbors_finished := 0
	for blk in block.board.get_surrounding(block.board_position):
		if blk is Block and blk.modifier is GoldModifier:
			neighbors_finished += blk.modifier.lines_finished
	return extra_score * (lines_finished + neighbors_finished)

func new_parent(new: Block) -> void:
	super(new)
	if new.board is GameBoard:
		block.board.LineFinished.connect(func(_v): lines_finished += 1)

#func _init(game: GameMain) -> void:
	#super(game)
	#display_name = "Gold"
	#description = "
		#Every line increases the amount of score this modifier gives by +%s.
		#Inherits bonus from neighbouring Gold modifiers." % \
		#[extra_score]
	#shader_path = "res://modifiers/shaders/bonus.gdshader"
	#mod_price = 5000
