extends TextureRect
class_name ShopButton

var asset_path: String
var board: ShopBoard
var blk: Block
var lable: RichTextLabel

func click_within_block(clk: Vector2) -> bool:
	@warning_ignore("integer_division")
	var right_x = global_position.x
	@warning_ignore("integer_division")
	var left_x = global_position.x + size.x
	@warning_ignore("integer_division")
	var up_y = global_position.y
	@warning_ignore("integer_division")
	var down_y = global_position.y + size.x
	
	return clk.x < left_x and clk.x > right_x and clk.y > up_y and clk.y < down_y

func destroy() -> void:
	lable.queue_free()
	queue_free()

func _init(img_path: String, brd: ShopBoard) -> void:
	asset_path = img_path
	board = brd
	blk = Block.new(BlockInfo.new(Enums.COLORS.WHITE), board._pm_pos(0, false), board)
	
	texture = load(img_path)
	position = Block.get_position_from_grid(board._pm_pos(0, false), board)
	size = Vector2(board.grid_size_px*2, board.grid_size_px*2)
	
	var lbl := RichTextLabel.new()
	lbl.text = str(Enums.shop_add_pm_price(board.game.round_num, board.game.max_pm))
	lbl.position = Block.get_position_from_grid(board._pm_pos(0, false) + Vector2i(0, -2), board)
	lbl.theme = load("res://text.tres")
	lbl.custom_minimum_size = Vector2(120,120)
	board.add_child(lbl)
	lable = lbl
