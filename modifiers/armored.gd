extends Modifier
class_name ArmoredModifier

var _block_info_copy: BlockInfo

#func trigger(who: Variant = null) -> int:
	#if who == null:
		#var new_info := block.info.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		#new_info.modifier = null
		#var new_block := Block.new(new_info, block.board_position, block.board, null)
		#block.board.block_list[block.board_position.x][block.board_position.y] = new_block
		#block.board.add_child(new_block)
	#else: print(who, "noSNFDO")
	#return 0

func post_trigger() -> void:
	var new_block := Block.new(_block_info_copy, block.board_position, block.board, null)
	#block.board.block_list[block.board_position.x][block.board_position.y] = new_block
	block.board.add_child(new_block)

func setup(game: GameMain = null) -> void:
	super(game)
	
	_block_info_copy = block.info.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_block_info_copy.modifier = null
