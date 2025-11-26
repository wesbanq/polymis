extends Resource
class_name PolyminoShape

@export_range(0.0, 2.0, 0.1) var weight: float = 1.0
@export var shape_string: Array[BlockInfo] = [null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]
@export var rotation_center: Enums.ROTATION_CENTER = Enums.ROTATION_CENTER.FOUR

var bottom2: int:
	get: return bottom2 if bottom2 else calculate_bottom().min()
var bottom: Array[int]:
	get: return bottom if bottom else calculate_bottom()

static func get_board_position_from_hex(n: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(n - 4*int(n/4), int(n/4))

static func get_hex_from_board_position(position: Vector2i) -> int:
	return 4*position.y + position.x

func calculate_bottom() -> Array[int]:
	var new_bottom: Array[int] = [-1, -1, -1, -1]
	for i in shape_string.size():
		var pos = get_board_position_from_hex(i)
		if shape_string[i] and new_bottom[pos.x] == -1:
			new_bottom[pos.x] = i
	new_bottom = new_bottom.filter(func(v): return true if v != -1 else false)
	
	if new_bottom.size() == 0:
		if shape_string.size() == 0:
			push_error("failed to calculate bottom blocks of polymino, shape_string is empty")
		else:
			push_error("failed to calculate bottom blocks of polymino")
	
	bottom = new_bottom
	bottom2 = new_bottom.min()
	return new_bottom

func create_polymino(board: Board, origin: Vector2i = Vector2i(0, 0), shop: bool = false) -> Polymino:
	return Polymino.new(self, board, origin, shop)

#static func get_mod_name(name: String) -> Modifier:
	#return (Enums.MODIFIERS[name.to_lower()].new() if Enums.MODIFIERS.keys().find(name.to_lower()) != -1 else null)
static func get_mod_name(name: String) -> String:
	return Enums.MODIFIERS_PATHS[name] if Enums.MODIFIERS_PATHS.keys().find(name) != -1 else ""

static func from_string(s: String, rc: Enums.ROTATION_CENTER) -> PolyminoShape:
	var new_shape: Array[BlockInfo] = [null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]
	for blk in s.split(" "):
		var new_pos := blk[0].hex_to_int()
		var new_mod := load(get_mod_name(blk.right(-1).to_lower()))
		var new_info := BlockInfo.new(Enums.COLORS.WHITE, new_mod)
		new_shape[new_pos] = new_info
	
	return PolyminoShape.new(new_shape, rc)

func _init(shape: Array[BlockInfo] = [null], center: Enums.ROTATION_CENTER = Enums.ROTATION_CENTER.FOUR) -> void:
	if shape.size() < 16: return
	shape_string = shape
	rotation_center = center
	calculate_bottom()
