extends TextureRect
class_name ShopButton

var asset_path: String
var board: ShopBoard
var blk: Block
var lable: GridLabel
var grid_pos: Vector2i
var active := true:
	set(v): active = v; material.set_shader_parameter("active", active)

func click_within_block(clk: Vector2) -> bool:
	if not active: return false
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

func _rescale() -> void:
	position = Block.get_position_from_grid(grid_pos, board)
	size = Vector2(board.grid_size_px*2, board.grid_size_px*2)

func _init(img_path: String, brd: ShopBoard, g_p: Vector2i, act: bool = active) -> void:
	asset_path = img_path
	board = brd
	grid_pos = g_p
	blk = Block.new(BlockInfo.new(Enums.COLORS.WHITE), board._pm_pos(0, false), board, null)
	
	texture = load(img_path)
	#position = Block.get_position_from_grid(board._pm_pos(0, false), board)
	material = ShaderMaterial.new()
	material.shader = Enums.UI.INACTIVE_SHADER
	active = act
	size = Vector2(board.grid_size_px*2, board.grid_size_px*2)
	
	board.ChangedAttr.connect(func(name: String, _val: Variant) -> void:
		if name == "grid_size_px": _rescale()
	)
	
	lable = GridLabel.new(
		grid_pos + Vector2i(0, -2), 
		str(Enums.shop_add_pm_price(board.game.round_num, board.game.max_pm)), 
		board)
	board.add_child(lable)
	_rescale()
