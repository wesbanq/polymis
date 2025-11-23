extends Node

const SEED_LENGTH := 8
const SEED_CHARACTERS := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

var rng := RandomNumberGenerator.new()
var current_seed := 0:
	set(v): current_seed = v; rng.seed = v; LimboConsole.info("Changed RNG seed to %d." % v)

func generate_seed() -> String:
	var new_seed := ""
	for i in SEED_LENGTH:
		new_seed += SEED_CHARACTERS[randi_range(0, SEED_CHARACTERS.size()-1)]
	return new_seed

@warning_ignore("shadowed_global_identifier")
func set_seed(seed: String) -> void:
	if seed.length() - SEED_LENGTH != 0: 
		push_error("given seed: %s. is not the correct length: %d" % [seed, SEED_LENGTH])
		LimboConsole.info("Wrong size seed given. Expected string of size: %d." % SEED_LENGTH)
		return
	
	#hex
	if seed.is_valid_hex_number():
		current_seed = seed.hex_to_int()
	else:
		push_error("non hex seed given: %s" % seed)
		LimboConsole.Info("A non-hex string given as the seed.")
		return
	
	print(current_seed)

@warning_ignore("shadowed_global_identifier")
func randi(min: int, max: int) -> int:
	return rng.randi_range(min, max)

@warning_ignore("shadowed_global_identifier")
func randf(min: float, max: float) -> float:
	return rng.randf_range(min, max)

func pick_random_weight(ranges: Array[float], items: Array[Variant]) -> Variant:
	var w := self.randf(0, ranges[-1])
	var left := 0
	var right := ranges.size()-1
	#binary search w/ slight changes
	while left <= right:
		@warning_ignore("integer_division")
		var mid := left + (right - left)/2
		if ranges[mid] > w and (ranges[mid-1] < w if mid > 0 else true):
			#
			return items[mid]
		elif ranges[mid] < w:
			left = mid+1
		elif ranges[mid] > w:
			right = mid-1
	
	push_error("failed to return item. w: %f. ranges: %v" % [w, ranges])
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
