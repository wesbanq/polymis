extends Sprite2D
class_name Block

var board: Board
var board_position: Vector2i

var color: Color
var score_amount: int = 100
var modifier: Modifier: # null = no modifier
	set(new): modifier = new; if modifier: modifier.block = self

var block_path = preload("res://block.png")
var shader_path = preload("res://block.gdshader")
var info: BlockInfo

var t

func score() -> int:
	if modifier: score_amount += modifier.trigger()
	destroy()
	return score_amount

func destroy() -> void:
	queue_free()
	if board.block_list[board_position.x][board_position.y] == self:
		board.block_list[board_position.x][board_position.y] = null

func _process(_delta: float) -> void:
	if board:
		scale = Vector2(board.grid_size_px/32., board.grid_size_px/32.)
		position = get_position_from_grid(board_position, board)
		if board.game.show_block_position: t.text = "(%s, %s)" % [board_position.x, board_position.y]
		else: t.text = ""

static func get_position_from_grid(grid_pos: Vector2i, brd: Board) -> Vector2:
	@warning_ignore("integer_division")
	return Vector2(brd.board_size_px.x/2. + (brd.grid_size_px * (grid_pos.x-(brd.width/2))), \
				   brd.board_size_px.y/2. - (brd.grid_size_px * (grid_pos.y-(brd.height/2)))) + \
			Vector2(brd.grid_size_px/2., -brd.grid_size_px/2.)

func click_within_block(clk: Vector2) -> bool:
	@warning_ignore("integer_division")
	var right_x = global_position.x + board.grid_size_px/2
	@warning_ignore("integer_division")
	var left_x = global_position.x - board.grid_size_px/2
	@warning_ignore("integer_division")
	var up_y = global_position.y + board.grid_size_px/2
	@warning_ignore("integer_division")
	var down_y = global_position.y - board.grid_size_px/2
	
	return clk.x > left_x and clk.x < right_x and clk.y < up_y and clk.y > down_y

func _ready() -> void:
	if board:
		scale = Vector2(board.grid_size_px/32., board.grid_size_px/32.)
		position = get_position_from_grid(board_position, board)
		if board.game.show_block_position: t.text = "(%s, %s)" % [board_position.x, board_position.y]
		else: t.text = ""

func _init(b_i: BlockInfo, b: Vector2i, brd: Board):
	#deep duplicate to make it local to scene
	#prevents bug with changing the blockinfo in shop
	info = b_i.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	color = info.color
	board = brd
	board_position = b
	modifier = info.modifier
	
	texture = block_path
	if modifier: # chk if block has modifier
		material = modifier.get_shader()
	else:
		material = ShaderMaterial.new()
		material.shader = shader_path
	
	material.set_shader_parameter("tint", Vector4(color.r, color.g, color.b, 1))
	#position = Vector2(board_position.x * board.grid_size_px + board_position.x * board.grid_padding_px, -board_position.y * board.grid_size_px - board_position.y * board.grid_padding_px)
	
	t = Label.new()
	t.z_index = 100
	add_child(t)
