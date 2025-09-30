extends Resource
class_name Modifier

@export var display_name: String
@export var description: String
@export var shader_path: String

@export var mod_price := 1
@export var weight := 1.0

var block: Block:
	set = new_parent

func get_shader() -> ShaderMaterial:
	var shader := ShaderMaterial.new()
	shader.shader = load(shader_path)
	return shader

func new_parent(new: Block) -> void:
	#print(new, self)
	block = new

func trigger(_who: Variant = null) -> int:
	return 0
