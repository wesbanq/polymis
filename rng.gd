extends Node

var rng := RandomNumberGenerator.new()
var current_seed := 0

@warning_ignore("shadowed_global_identifier")
func initialize(seed: int) -> void:
	rng.seed = seed
	current_seed = seed

@warning_ignore("shadowed_global_identifier")
func randi(min: int, max: int) -> int:
	return rng.randi_range(min, max)

@warning_ignore("shadowed_global_identifier")
func randf(min: float, max: float) -> float:
	return rng.randf_range(min, max)

func pick_random_weight(ranges: Array[float], items: Array[Variant]) -> Variant:
	var w := self.randf(0, ranges.max())
	var left := 0
	var right := ranges.size()-1
	#binary search w/ slight changes
	while left <= right:
		@warning_ignore("integer_division")
		var mid := left + int((right - left)/2)
		if ranges[mid] > w and (ranges[mid-1] < w if mid > 0 else true):
			return items[mid]
		elif ranges[mid] < w:
			left = mid+1
		elif ranges[mid] > w:
			right = mid-1
	
	push_error("FAILED TO GET SHAPE")
	return

func pick_random(src: Array[Variant]) -> Variant:
	return src[self.randi(0, len(src)-1)]

func get_random_color() -> Color:
	var t = Enums.COLORS.keys()
	return Enums.COLORS[self.pick_random(t)]

func shuffle(arr: Array[Variant]) -> Array[Variant]:
	var res := []
	for i in arr.size():
		var rand := self.randi(0, arr.size()-1)
		res.append(arr[rand])
		arr.remove_at(rand)
	return res
