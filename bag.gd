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
