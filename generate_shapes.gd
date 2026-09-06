@abstract
class_name ShapeGen

const MAX_SIZE := PolyminoShape.POLYMINO_SIZE*PolyminoShape.POLYMINO_SIZE
const GROUP_PERCENTAGE: Array[float] = [
	13.0,
	6.0,
	4.0,
	33.0,
	10.0,
	6.0,
	5.0,
	5.0,
	5.0,
	5.0,
	5.0,
	5.0,
	5.0,
	5.0,
	5.0,
	1.0
]

static var every_pm: Array[PolyminoShape] = []

static func _get_adjacent(pos: Vector2i, visited: Array) -> Array[Vector2i]:
	var arr: Array[Vector2i] = []
	
	if pos.y <= 3 and not pos + Vector2i.DOWN in visited:
		arr.push_back(pos + Vector2i.DOWN)
	if pos.x <= 3 and not pos + Vector2i.RIGHT in visited:
		arr.push_back(pos + Vector2i.RIGHT)
	if pos.x > 0 and not pos + Vector2i.LEFT in visited:
		arr.push_back(pos + Vector2i.LEFT)
	if pos.y > 0 and not pos + Vector2i.UP in visited:
		arr.push_back(pos + Vector2i.UP)
	
	return arr

# for some bizzare reason gdscript doesnt have nested array types
static func _gen_next_group(group):
	var res = []
	for shape: Array in group:
		for blk in shape:
			var adjacent := _get_adjacent(blk, shape)
			for extra in adjacent:
				var dupe := shape.duplicate()
				dupe.append(extra)
				res.append(dupe)
	
	return res

static func _rotated(shape: Array) -> Array[Vector2i]:
	var minx = null
	var miny = null
	for blk in shape:
		blk = Vector2i(blk.y, -blk.x)
		if not minx or blk.x < minx:
			minx = blk.x
		if not miny or blk.y < miny:
			miny = blk.y
	
	for blk in shape:
		blk = Vector2i(blk.x - minx, blk.y - miny)
	
	return shape

static func _same_shape(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	for blk in a:
		if blk not in b:
			return false
	
	return true 

static func _remove_duplicate(group):
	var res = []
	for source: Array in group:
		var unique := true
		for check: Array in res:
			var cur := source.duplicate()
			for _i in 4:
				if _same_shape(cur, check):
					unique = false
					break
				cur = _rotated(cur)
		if unique:
			res.append(source)
	
	return res

static func generate_shapes() -> Array[PolyminoShape]:
	var groups = [[[Vector2i(0, 0)]]]
	var total_size: int = 0
	for size in MAX_SIZE:
		var new_group = _remove_duplicate(_gen_next_group(groups[-1]))
		total_size += new_group.size()
		groups.append(new_group)
		
	
	#var flattened_groups = []
	#for group in groups:
		#flattened_groups.append_array(group)
	
	var res: Array[PolyminoShape] = []
	for i in groups.size():
		var group_size: int = groups[i].size()
		for shape: Array in groups[i]:
			var new_polyminoshape := PolyminoShape.new()
			for blk in shape:
				new_polyminoshape.shape_string[PolyminoShape.get_hex_from_board_position(blk)] = BlockInfo.new()
			new_polyminoshape.weight = GROUP_PERCENTAGE[i] / group_size
			
			res.append(new_polyminoshape)
	
	return []

static func _static_init() -> void:
	every_pm = generate_shapes()
