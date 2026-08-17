extends Resource
class_name Bag

@export var shapes: Array[PolyminoShape]

var next_size: int = 3
var _shuffled: Array[PolyminoShape]

#func peek() -> Array[PolyminoShape]:
	#return _shuffled.slice(0, next_size)

func _ensure_size() -> void:
	if _shuffled.size() <= next_size:
		reshuffle()
		print("reshuf")

func add_to_bag(ps: PolyminoShape) -> void:
	shapes.append(ps)

func peek(n: int = 0) -> PolyminoShape:
	_ensure_size()
	return _shuffled[n]

func reshuffle(full: bool = false) -> void:
	if full: _shuffled = []
	while _shuffled.size() <= next_size:
		_shuffled.append_array(RNG.shuffle(shapes.duplicate()))

func get_next() -> PolyminoShape:
	_ensure_size()
	return _shuffled.pop_front()

static func load_bag_resource(path: String, _game: GameMain) -> Bag:
	var new_bag: Bag = load(path).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	#for ps in new_bag.shapes:
		#for blk in ps.shape_string:
			#if blk and blk.modifier:
				#blk.modifier.setup(game)
	return new_bag
