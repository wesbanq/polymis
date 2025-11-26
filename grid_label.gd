extends RichTextLabel
class_name GridLabel

var grid_pos: Vector2i
var board: Board

func _rescale() -> void:
	position = Block.get_position_from_grid(grid_pos, board)
	size = Vector2(board.grid_size_px*2, board.grid_size_px*2)

func change_text(txt: String) -> void:
	text = txt

func _init(g_p: Vector2i, txt: String, brd: Board) -> void:
	grid_pos = g_p
	board = brd
	text = txt
	
	theme = Enums.UI.TEXT_THEME
	position = Block.get_position_from_grid(grid_pos, board)
	
	fit_content = true
	scroll_active = true
	autowrap_mode = TextServer.AUTOWRAP_OFF
	#custom_minimum_size = Vector2(120, 120)
	
	#board.UpdatedBoardSize.connect(_rescale)
	@warning_ignore("shadowed_variable_base_class")
	board.ChangedAttr.connect(func(name: String, _val: Variant) -> void:
		if name == "grid_size_px": _rescale()
	)
	
	#board.add_child(self)
