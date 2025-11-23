extends Node2D
class_name Polymino

var game_board: Board
var ghost: Ghost

var shape: Array[bool]
var blocks: Array[Block]
var rotation_center: Enums.ROTATION_CENTER = Enums.ROTATION_CENTER.FOUR
var bottom: Array[int]
var bottom2: int
var string: PolyminoShape

var buyable := false
var enable_ghost: bool = true

signal DownTimer

func check_collision(direction: Vector2i, all: bool = true) -> bool:
	if all:
		for v in blocks:
			if v is Block and game_board.check_bounds(v.board_position + direction):
				return true
	else:
		for v in bottom:
			if game_board.check_bounds(blocks[v].board_position + direction):
				return true
	return false

static func get_delta_cw(grid_size: int, b_p: Vector2i) -> Vector2i:
	return Vector2i(-b_p.x+b_p.y, grid_size-1-b_p.x-b_p.y)

static func get_delta_ccw(grid_size: int, b_p: Vector2i) -> Vector2i:
	return Vector2i(grid_size-1-b_p.x-b_p.y, -b_p.y+b_p.x)

func turn(cw: bool = true) -> void:
	#x': -x+y, y': grid_size-1-x-y
	#'x: grid_size-1-x-y, 'y: -y+x
	## phasing through walls FIX
	var grid_size = rotation_center
	#print(grid_size,"grds")
	var shift
	var final: Array[Block]
	var final_d: Array[Vector2i]
	for s in range(-2, 3):
		var c
		var t_final: Array[Block]
		t_final.resize(16)
		var t_final_d: Array[Vector2i]
		t_final_d.resize(16)
		for i in blocks.size():
			var v = blocks[i]
			var b_p = PolyminoShape.get_board_position_from_hex(i)
			var p_delta = get_delta_cw(grid_size, b_p) if cw else get_delta_ccw(grid_size, b_p)
			t_final[PolyminoShape.get_hex_from_board_position(b_p + p_delta)] = v
			t_final_d[PolyminoShape.get_hex_from_board_position(b_p + p_delta)] = p_delta
			if v is Block:
				var final_bp = v.board_position + p_delta
				#print(i,p_delta,PolyminoShape.get_hex_from_board_position(b_p + p_delta),"BP")
				final_bp.x += s
				if game_board.check_bounds(final_bp):
					c = true
					break
		@warning_ignore("unassigned_variable")
		if not c and (shift == null or absi(shift) > absi(s)):
			final = t_final
			final_d = t_final_d
			shift = s
	
	if shift == null:
		#print("rotation failed")
		return
	
	#print(shift, final)
	blocks = final
	for i in blocks.size():
		var v = blocks[i]
		if v is Block:
			v.board_position += final_d[i]
			v.board_position.x += shift
	
	bottom = calculate_bottom()
	bottom2 = calculate_bottom2()
	if ghost:
		#ghost.turn(cw)
		ghost.UpdateGhost.emit()

func move(direction: Vector2i) -> void:
	if not check_collision(direction):
		for v in blocks:
			if v is Block:
				v.board_position += direction
		if ghost: ghost.UpdateGhost.emit()
	elif not (abs(direction.x) > 0):
		if ghost: ghost.queue_free()
		game_board.PolyminoPlaced.emit(self)

func snap_down():
	@warning_ignore("shadowed_global_identifier")
	var max = blocks[bottom2].board_position.y
	for Z in bottom:
		var v = blocks[Z]
		var i = game_board.block_list[v.board_position.x].rfind_custom(func(e): return e is Block, v.board_position.y)
		if i == -1: continue
		var n = v.board_position.y - game_board.block_list[v.board_position.x][i].board_position.y - 1
		#print("%s, %s" % [i, n])
		if max > n:
			max = n
	move(Vector2i(0, -max))

func calculate_bottom2() -> int:
	var result = Vector2i(-1, -1)
	for i in blocks.size():
		var v = blocks[i]
		if v is Block:
			var pos = PolyminoShape.get_board_position_from_hex(i)
			#print(pos, result)
			if pos.y < result.y or result.y == -1:
				result = pos
	return PolyminoShape.get_hex_from_board_position(result)

func calculate_bottom() -> Array[int]:
	var result: Array[int] = [-1, -1, -1, -1]
	for i in blocks.size():
		var v = blocks[i]
		if v is Block:
			var pos = PolyminoShape.get_board_position_from_hex(i)
			if pos.y < PolyminoShape.get_board_position_from_hex(result[pos.x]).y or result[pos.x] == -1:
				result[pos.x] = i
	return result.filter(func(v): return v > -1)

func copy_blocks(src: Variant, origin: Vector2i = Vector2i(0, 0)) -> void:
	#creates blocks in the blocks array but doesnt parent so the new blocks dont automatically appear
	blocks = []
	blocks.resize(16)
	
	if src is PolyminoShape:
		for i in src.shape_string.size():
			var v = src.shape_string[i]
			if v != null:
				blocks[i] = Block.new(v, PolyminoShape.get_board_position_from_hex(i) + origin, game_board, src, i)
	elif src is Polymino:
		if not self is Ghost: push_warning("used pm not ghost") 
		for i in src.blocks.size():
			#var new_shape = src.string.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
			if src.blocks[i]:
				var v = src.blocks[i]
				var new_info = v.info.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
				new_info.modifier = null
				blocks[i] = Block.new(new_info, v.board_position, game_board, src.string, i)
	bottom = src.bottom
	bottom2 = src.bottom2

func destroy() -> void:
	if ghost: ghost.queue_free()
	queue_free()

func _init(ps: PolyminoShape, board: Board, origin: Vector2i = Vector2i(0, 0), shop: bool = false) -> void:
	string = ps
	shape.assign(string.shape_string.map(func(v): return v is Modifier))
	rotation_center = string.rotation_center
	game_board = board
	buyable = shop
	
	DownTimer.connect(func():
		#print("a")
		move(Vector2i(0, -1))
	)
	
	copy_blocks(string, origin)
	for v in blocks:
		if v is Block:
			v.buyable = buyable
			add_child(v)
	#print(bottom, bottom2, calculate_bottom(), calculate_bottom2())

func _ready() -> void:
	if enable_ghost:
		ghost = Ghost.new(self)
