extends Resource
class_name Bag

@export var shapes: Array[PolyminoShape]

var next: PolyminoShape: 
	get = get_next

var _shuffled: Array[PolyminoShape]

func add_to_bag(ps: PolyminoShape) -> void:
	#print(ps)
	shapes.append(ps)

func get_shuffled() -> void:
	_shuffled = []
	for v in RNG.shuffle(shapes.duplicate()):
		_shuffled.append(v)

func get_next() -> PolyminoShape:
	var result: PolyminoShape = _shuffled.pop_front()
	if result:
		return result
	else:
		get_shuffled()
		return _shuffled.pop_front()
