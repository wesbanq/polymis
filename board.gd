extends Control
class_name Board

@export var rel_position: Vector2 = Vector2(2, -3)

@warning_ignore("unused_signal")
signal UpdatedBoardSize(size: Vector2)

var width := 10
var height := 20

var grid_size_px := 16
var grid_padding_px := 0

var board_size_px: Vector2:
	get: return Vector2(grid_size_px * width + grid_padding_px * (width-1), grid_size_px * height + grid_padding_px * (height-1))
var offsets: Vector2:
	get: return Vector2(-board_size_px.x/4, board_size_px.y/4)

@onready var game := $/root/GameMain
@onready var container := get_parent()
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

#func update_position() -> void:
	#var size = Vector2(grid_size_px * width + grid_padding_px * (width-1), grid_size_px * (height-4) + grid_padding_px * (height-5)) * scale
	#position = Vector2(get_viewport_rect().size.x/2.0 - size.x/2.0, get_viewport_rect().size.y/2.0 + size.y/2.0)
	#UpdatedBoardSize.emit(size)

func _add_polymino(ps: PolyminoShape, origin: Vector2i = Vector2i(int(width/2.0 - 2)+1, height-4), ghost: bool = true) -> Polymino:
	var new_polymino := ps.create_polymino(self, origin)
	new_polymino.enable_ghost = ghost
	
	add_child(new_polymino)
	update_block_list()
	return new_polymino

func update_position() -> void:
	#offset_left = offsets.x
	#offset_top = offsets.y
	custom_minimum_size = board_size_px

func change_board_size(new_size: Vector2i) -> void:
	if new_size.x > width:
		width = new_size.x
	if new_size.y > height:
		height = new_size.y
	#update_position()

#func update(size: Vector2) -> void:
	##scale = main_board.scale
	##position = Vector2(main_board.position.x - width * grid_size_px - grid_padding_px, main_board.position.y + size.y - height * grid_size_px)
	##position = rel_position * grid_size_px + (-(rel_position - Vector2.ONE) * grid_padding_px) + (main_board.position + size)
	#position = Vector2()

func _init(s_x: int = 10, s_y: int = 20, scle: float = 1.0) -> void:
	height = s_y+4
	width = s_x
	scale = Vector2(scle, scle)
	
	#size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	#set_anchors_preset(PRESET_CENTER)
	update_position()
