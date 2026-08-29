extends Resource
class_name Bag

@export var shapes: Array[PolyminoShape]

var next_size: int = 3
var _shuffled: Array[PolyminoShape]

signal BagUpdated

#func peek() -> Array[PolyminoShape]:
	#return _shuffled.slice(0, next_size)

func _ensure_size(n: int) -> void:
	if _shuffled.size() <= n:
		reshuffle(false, n)
		print("reshuf")
		BagUpdated.emit()

func add_to_bag(ps: PolyminoShape) -> void:
	shapes.append(ps)
	BagUpdated.emit()

func peek(n: int = 0) -> PolyminoShape:
	if n < 0: 
		push_error("out of range n: ", n)
		return
	_ensure_size(n)
	return _shuffled[n]

func get_next_n(n: int) -> Array[PolyminoShape]:
	if n <= 0: 
		push_error("out of range n: ", n)
		return []
	_ensure_size(n)
	return _shuffled.slice(0, n)

func reshuffle(full: bool = false, n: int = next_size) -> void:
	if full: _shuffled = []
	while _shuffled.size() <= n:
		_shuffled.append_array(RNG.shuffle(shapes.duplicate()))
	BagUpdated.emit()

#TODO
func temp_remove(idx: int) -> void:
	pass

#TODO
func temp_add(pm: PolyminoShape) -> void:
	pass

#TODO
func undo_temp() -> void:
	pass

func get_next() -> PolyminoShape:
	_ensure_size(1)
	return _shuffled.pop_front()

static func load_bag_resource(path: String, _game: GameMain) -> Bag:
	var new_bag: Bag = load(path).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	#for ps in new_bag.shapes:
		#for blk in ps.shape_string:
			#if blk and blk.modifier:
				#blk.modifier.setup(game)
	return new_bag
