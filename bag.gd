extends Resource
class_name Bag

@export var shapes: Array[PolyminoShape]

var _shuffled: Array[PolyminoShape]

signal BagUpdated

#func peek() -> Array[PolyminoShape]:
	#return _shuffled.slice(0, next_size)

func _ensure_size(n: int) -> void:
	if _shuffled.size() <= n:
		reshuffle(false, n)
		print("reshuf")
		BagUpdated.emit()

func add(ps: PolyminoShape) -> void:
	shapes.append(ps)
	BagUpdated.emit()

func size() -> int:
	return shapes.size()

static func _erase(arr: Array[PolyminoShape], ps: PolyminoShape) -> int:
	var removed := 0
	var idx := arr.find(ps)
	while idx != -1:
		arr.remove_at(idx)
		removed += 1
		idx = arr.find(ps)
	return removed

func remove(ps: PolyminoShape) -> void:
	_erase(shapes, ps)
	var n := _erase(_shuffled, ps)
	_ensure_size(n)
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

const _NEXT_SIZE := 3
func reshuffle(full: bool = false, n: int = _NEXT_SIZE) -> void:
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
