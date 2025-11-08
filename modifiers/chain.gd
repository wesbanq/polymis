extends Modifier
class_name ChainModifier

var direction := 1 # 1 - up, -1 - down

func trigger(_who: Variant = null) -> int:
	var score = 0
	for blk in block.board.block_list[block.board_position.x] \
	.slice(block.board_position.y + direction, len(block.board.block_list), direction):
		if blk is Block and blk.modifier:
			score += blk.modifier.trigger(block)
	return score

func new_parent(new: Block) -> void:
	super(new)
	if new.board is GameBoard:
		block.board.PolyminoPlaced.connect(func(_v): direction *= -1)

#func setup(game: GameMain = null) -> void:
	#super(game)
	#display_name = "Chain"
	#description = "
		#Triggers all modifiers in the column either below or above this block. Direction switches every polymino placed."
	#shader_path = "res://modifiers/shaders/bonus.gdshader"
	#mod_price = 3000
