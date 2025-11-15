extends Resource
class_name Modifier

@export var display_name: String
@export_multiline var description: String
@export var shader_path: String = fallback_shader_path
const fallback_shader_path := "res://modifiers/shaders/fallback.gdshader"

@export var mod_price := 1
@export var weight := 1.0

var block: Block:
	set = new_parent
var board: GameBoard:
	get: return block.board if block else null
var _game: GameMain
@warning_ignore("unused_private_class_variable")
var _copy := false

func get_shader() -> ShaderMaterial:
	if shader_path.length() > 6:
		var shader := ShaderMaterial.new()
		shader.shader = load(shader_path)
		return shader
	else:
		return null

func new_parent(new: Block) -> void:
	#print(new, self)
	block = new

#trigger functions run sequentially for blocks from left to right in a completed line

#runs for each block before the trigger function
func pre_trigger() -> void:
	pass

#runs for each block after all the lines have been triggered
func post_trigger() -> void:
	pass

#returns the amount of extra score that should be added to the lines score
func trigger(_who: Variant = null) -> int:
	return 0

func get_from_prototype(val: String) -> Variant:
	if block:
		if block.prototype_shape.shape_string[block.prototype_shape_idx]:
			return block.prototype_shape.shape_string[block.prototype_shape_idx].modifier.get(val)
		else:
			push_error("no prototype")
	else:
		push_error("no block")
	return null

func setup(game: GameMain = null) -> void:
	_game = game
	#_copy = cpy
