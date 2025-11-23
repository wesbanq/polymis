extends Resource
class_name Bag

@export var shapes: Array[PolyminoShape]

var next: PolyminoShape: 
	get = _get_next

var _shuffled: Array[PolyminoShape]

func add_to_bag(ps: PolyminoShape) -> void:
	shapes.append(ps)

func reshuffle() -> void:
	_shuffled = []
	for v in RNG.shuffle(shapes.duplicate()):
		_shuffled.append(v)

func _get_next() -> PolyminoShape:
	var result: PolyminoShape = _shuffled.pop_front()
	if result:
		return result
	else:
		reshuffle()
		return _shuffled.pop_front()

static func load_bag_resource(path: String, game: GameMain) -> Bag:
	var new_bag: Bag = load(path).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for ps in new_bag.shapes:
		for blk in ps.shape_string:
			if blk and blk.modifier:
				blk.modifier.setup(game)
	
	return new_bag
