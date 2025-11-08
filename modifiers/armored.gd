extends Modifier
class_name ArmoredModifier

func trigger(who: Variant = null) -> int:
	if who == null:
		var new_info := block.info.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		new_info.modifier = null
		var new_block := Block.new(new_info, block.board_position, block.board, null)
		block.board.block_list[block.board_position.x][block.board_position.y] = new_block
		block.board.add_child(new_block)
	else: print(who, "noSNFDO")
	return 0

#func setup(game: GameMain = null) -> void:
	#super(game)
	#display_name = "Armored"
	#description = "
		#Stops the block from disappearing when a line is finished.
		#Works once."
	#shader_path = "res://modifiers/shaders/bonus.gdshader"
	#mod_price = 800
