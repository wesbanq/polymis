extends Resource
class_name Modifier

@export var display_name: String
@export_multiline var description: String
@export var shader_path: String
const fallback_shader_path := "res://modifiers/shaders/fallback.gdshader"

@export var mod_price := 1
@export var weight := 1.0

var block: Block:
	set = new_parent
var board: GameBoard:
	get: return block.board if block else null
var _game: GameMain

func get_shader() -> ShaderMaterial:
	var shader := ShaderMaterial.new()
	shader.shader = load(shader_path if shader_path.length() > 6 else fallback_shader_path)
	return shader

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

func setup(game: GameMain = null) -> void:
	_game = game
