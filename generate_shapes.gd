extends Node

const GRID_SIZE := PolyminoShape.POLYMINO_SIZE
const CELL_COUNT := GRID_SIZE * GRID_SIZE

## percentage weight given to each entire size-group (index 0 = size 1, ..., index 15 = size 16);
## split evenly between however many distinct shapes end up in that group, so a group with more
## shapes doesn't dominate the shop pool just for having more members
var group_percentage: Array[float] = [
	15.0,
	10.0,
	15.0,
	40.0,
	10.0,
	6.0,
	2.0,
	2.0,
	2.0,
	2.0,
	2.0,
	2.0,
	2.0,
	2.0,
	2.0,
	4.0,
]:
	set(v):
		if v is Array[float] and v.size() == 16:
			group_percentage = v
			every_pm = generate_shapes()
		else:
			push_error("wrong arg type or wrong array size for group_percentage.")

static var every_pm: Array[PolyminoShape] = []

static func _cells_from_mask(mask: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in CELL_COUNT:
		if mask & (1 << i):
			cells.append(PolyminoShape.get_board_position_from_hex(i))
	return cells

static func _connected(cells: Array[Vector2i]) -> bool:
	var to_visit: Array[Vector2i] = [cells[0]]
	var seen: Array[Vector2i] = [cells[0]]
	while not to_visit.is_empty():
		var cur: Vector2i = to_visit.pop_back()
		for delta in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = cur + delta
			if n in cells and not n in seen:
				seen.append(n)
				to_visit.append(n)
	return seen.size() == cells.size()

static func _normalized(cells: Array[Vector2i]) -> Array[Vector2i]:
	var min_x := cells[0].x
	var min_y := cells[0].y
	for c in cells:
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
	var shifted: Array[Vector2i] = []
	for c in cells:
		shifted.append(c - Vector2i(min_x, min_y))
	return shifted

static func _rotated_cw(cells: Array[Vector2i]) -> Array[Vector2i]:
	var rotated: Array[Vector2i] = []
	for c in cells:
		rotated.append(Vector2i(c.y, -c.x))
	return _normalized(rotated)

## order-independent string key for a cell set, so two arrays holding the same
## positions in a different order still compare equal
static func _key(cells: Array[Vector2i]) -> String:
	var codes: Array[int] = []
	for c in cells:
		codes.append(c.x * GRID_SIZE + c.y)
	codes.sort()
	var parts: Array[String] = []
	for code in codes:
		parts.append(str(code))
	return ",".join(parts)

## one-sided canonical key: the smallest key among the shape's 4 rotations.
## reflections are NOT folded together here -- mirrored pieces (S/Z, L/J) are meant
## to stay distinct pieces, matching how Polymino.turn() only ever rotates in place
static func _canonical_key(cells: Array[Vector2i]) -> String:
	var cur := _normalized(cells)
	var best := _key(cur)
	for _i in 3:
		cur = _rotated_cw(cur)
		var k := _key(cur)
		if k < best:
			best = k
	return best

static func _rotation_center_for(cells: Array[Vector2i]) -> Enums.ROTATION_CENTER:
	var max_x := 0
	var max_y := 0
	for c in cells:
		max_x = maxi(max_x, c.x)
		max_y = maxi(max_y, c.y)
	var span := maxi(max_x, max_y) + 1
	if span <= 2:
		return Enums.ROTATION_CENTER.TWO
	elif span == 3:
		return Enums.ROTATION_CENTER.THREE
	return Enums.ROTATION_CENTER.FOUR

static func _build_shape(cells: Array[Vector2i], weight: float) -> PolyminoShape:
	var shape := PolyminoShape.new()
	for c in cells:
		shape.shape_string[PolyminoShape.get_hex_from_board_position(c)] = BlockInfo.new()
	shape.weight = weight
	shape.rotation_center = _rotation_center_for(cells)
	shape.calculate_bottom()
	return shape

## brute-force over every subset of the 4x4 grid (2^16, trivially fast) rather than growing
## outward from a fixed corner cell: growth-from-one-anchor can never produce a shape whose
## every rotation leaves that anchor's grid position empty (e.g. the plus-pentomino, which is
## rotationally symmetric with no filled bounding-box corner in any orientation)
func generate_shapes() -> Array[PolyminoShape]:
	# canonical_key -> cells, grouped by size so each group's group_percentage can be
	# split evenly across however many distinct shapes actually landed in it
	var groups_by_size: Array[Dictionary] = []
	groups_by_size.resize(CELL_COUNT + 1)
	for i in groups_by_size.size():
		groups_by_size[i] = {}

	for mask in range(1, 1 << CELL_COUNT):
		var cells := _cells_from_mask(mask)
		if not _connected(cells):
			continue
		groups_by_size[cells.size()][_canonical_key(cells)] = cells

	var result: Array[PolyminoShape] = []
	for size in range(1, CELL_COUNT + 1):
		var group: Dictionary = groups_by_size[size]
		if group.is_empty():
			continue
		var per_shape_weight := group_percentage[size - 1] / group.size()
		for key in group:
			result.append(_build_shape(group[key], per_shape_weight))

	return result

func _init() -> void:
	every_pm = generate_shapes()
