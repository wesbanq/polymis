extends AbilityActive
class_name RemoveLast

var _last_placed: Array[Block] = []

func _change_last_placed(new: Polymino) -> void:
	_last_placed = new.blocks.filter(func(v): return v is Block)

func trigger() -> bool:
	_last_placed = _last_placed.filter(func(v): return v and v is Block)
	if _last_placed.size() > 0:
		for blk in _last_placed:
			if blk.board is GameBoard:
				blk.board.destroy_block_at(blk.board_position)
		_last_placed = []
		return true
	return false

func _init(gme: GameMain) -> void:
	super(gme)
	
	display_name = "Remove Last"
	description = "Removes last placed polymino."
	image_path = "res://abils/active/icons/gen_abil.png"
	sp_cost = 32
	
	game.PolyminoPlaced.connect(_change_last_placed)
	
