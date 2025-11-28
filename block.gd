extends Sprite2D
class_name Block

var board: Board
var board_position: Vector2i

var color: Color
var score_amount: int = 100
var modifier: Modifier: # null = no modifier
	set(new): modifier = new; if modifier: modifier.block = self

var prototype_shape: PolyminoShape
var prototype_shape_idx: int

var block_path = preload("res://block.png")
var default_shader_path = preload("res://block.gdshader")
var info: BlockInfo

var t
var buyable: bool
var ghost := false
var _hoverable: Hoverable = null

func _get_color_name() -> String:
	var i := Enums.COLORS.values().find(color)
	if i != -1:
		return Enums.COLORS.keys()[i]
	else:
		return "IM FUCKING KILLING MYSLEF"

func pre_trigger() -> void:
	if modifier:
		modifier.pre_trigger()

func post_trigger() -> void:
	if modifier:
		modifier.post_trigger()

func score() -> int:
	#possible bug gna leave it cuz it might lead to intnrsng tech
	if modifier: score_amount += modifier.trigger()
	return score_amount
	#fix VVV
	#return score_amount + modifier.trigger() if modifier else score_amount

func destroy() -> void:
	#potential modifier destroy trigger
	if _hoverable: 
		_hoverable.force_hide()
		_hoverable.free()
	queue_free()
	#if board.block_list[board_position.x][board_position.y] == self:
		#board.block_list[board_position.x][board_position.y] = null

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
		if not ghost: 
			_hoverable = Hoverable.new(
				self,
				click_within_block,
				modifier.display_name if modifier else _get_color_name(), 
				modifier.description if modifier else "",
				modifier.display_name_color if modifier else color,
				buyable
			)
			add_child(_hoverable)

func _init(b_i: BlockInfo, b: Vector2i, brd: Board, prototype: PolyminoShape, idx: int = 0, ghst: bool = false):
	#deep duplicate to make it local to scene
	#prevents bug with the shop changing blockinfo
	info = b_i.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	color = info.color
	board = brd
	board_position = b
	modifier = info.modifier.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) if info.modifier else null
	ghost = ghst
	
	prototype_shape = prototype if prototype else PolyminoShape.new()
	prototype_shape_idx = idx
	
	texture = block_path
	#mb like change it to be more elegant next time???????????????????????
	if modifier: # chk if block has modifier
		modifier._copy = true
		modifier.setup(board.game)
		var new_shader := modifier.get_shader()
		if new_shader:
			material = new_shader
		else:
			material = ShaderMaterial.new()
			material.shader = default_shader_path
	else:
		material = ShaderMaterial.new()
		material.shader = default_shader_path
	
	material.set_shader_parameter("tint", Vector4(color.r, color.g, color.b, 1))
	#position = Vector2(board_position.x * board.grid_size_px + board_position.x * board.grid_padding_px, -board_position.y * board.grid_size_px - board_position.y * board.grid_padding_px)
	
	t = Label.new()
	t.z_index = 100
	add_child(t)
