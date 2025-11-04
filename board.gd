extends Control
class_name Board

@export var rel_position: Vector2 = Vector2(2, -3)

@warning_ignore("unused_signal")
signal UpdatedBoardSize(size: Vector2)
signal ChangedAttr(name: String, new: Variant)

@onready var game: GameMain = $/root/GameMain
@onready var container := get_parent()

var width := 10
var height := 20:
	set(v): height = v; ChangedAttr.emit("height", v)

var _init_grid_size := func() -> int: ChangedAttr.emit("grid_size_px", game.default_grid_size_px); return game.default_grid_size_px
@onready var grid_size_px: int = _init_grid_size.call():
	set(v): grid_size_px = v; update_position(); ChangedAttr.emit("grid_size_px", v)
var grid_padding_px := 0:
	set(v): grid_padding_px = v; update_position()

var board_size_px: Vector2:
	#get: return Vector2(grid_size_px * (width+1) + grid_padding_px * (width-1), grid_size_px * (height) + grid_padding_px * (height-1))
	get: return Vector2((width+1) * grid_size_px + grid_padding_px * width - grid_padding_px - grid_size_px, \
						height * grid_padding_px + (height+1) * grid_size_px - grid_size_px - grid_padding_px)
var offsets: Vector2:
	get: return Vector2(-board_size_px.x/4, board_size_px.y/4)

var block_list#: Array[Array[Block]]

func update_block_list() -> void:
	block_list = []
	for i in width: 
		var t = []
		t.resize(height)
		block_list.append(t)
	for v in get_children():
		if not v.is_queued_for_deletion() and v is Block:
			#print("%s, x: %s, y: %s" % [v, v.board_position.x, v.board_position.y])
			block_list[v.board_position.x][v.board_position.y] = v

func get_surrounding(pos: Vector2i) -> Array[Block]:
	return [
		(block_list[pos.x + 1][pos.y] if pos.x+1 < width else null),
		(block_list[pos.x - 1][pos.y] if pos.x-1 > 0 else null),
		(block_list[pos.x][pos.y + 1] if pos.y+1 < height else null),
		(block_list[pos.x][pos.y - 1] if pos.y-1 > 0 else null)
	]

func _add_polymino(ps: PolyminoShape, origin: Vector2i = Vector2i(int(width/2.0 - 2)+1, height-4), ghost: bool = true) -> Polymino:
	var new_polymino := ps.create_polymino(self, origin)
	new_polymino.enable_ghost = ghost
	
	add_child(new_polymino)
	update_block_list()
	return new_polymino

func update_position() -> void:
	#offset_left = offsets.x
	#offset_top = offsets.y
	if container:
		##FIX ME
		#container.custom_minimum_size = board_size_px*1.1
		custom_minimum_size = board_size_px
	#custom_minimum_size = board_size_px

func change_board_size(new_size: Vector2i) -> void:
	if new_size.x > width:
		width = new_size.x
	if new_size.y > height:
		height = new_size.y
	#update_position()

func check_bounds(blk: Vector2i) -> bool:
		return blk.x >= width \
				or blk.y >= height \
				or blk.x < 0 \
				or blk.y < 0 \
				#or blk.y >= board.height-4 \
				#or (board.block_list[blk.x+1][blk.y] is Block \
				#or board.block_list[blk.x-1][blk.y] is Block \
				#or board.block_list[blk.x][blk.y+1] is Block \
				#or board.block_list[blk.x][blk.y-1] is Block \
				or block_list[blk.x][blk.y] is Block

#func update(size: Vector2) -> void:
	##scale = main_board.scale
	##position = Vector2(main_board.position.x - width * grid_size_px - grid_padding_px, main_board.position.y + size.y - height * grid_size_px)
	##position = rel_position * grid_size_px + (-(rel_position - Vector2.ONE) * grid_padding_px) + (main_board.position + size)
	#position = Vector2()

func _init(s_x: int = 10, s_y: int = 20, scle: float = 1.0) -> void:
	height = s_y
	width = s_x
	scale = Vector2(scle, scle)
	
	set_anchors_preset(Control.PRESET_CENTER)
	
	update_position()
