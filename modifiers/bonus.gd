extends Modifier
class_name BonusModifier

@export var bonus_amount := 100
@export var sur_bonus_am := 25
@export var sur_bonus_bonus_am := 50
#TODO REDO THIS MODIFIER

func get_shader() -> ShaderMaterial:
	print(shader_path)
	var shader = super()
	shader.set_shader_parameter("e_tint", Color.hex(0x00b000))
	return shader

func trigger(_who: Variant = null) -> int:
	var sur := block.board.get_surrounding(block.board_position).filter(func(v): return v is Block and v.modifier)
	
	var bonus_num := sur.filter(func(v): return v.modifier is BonusModifier).size()
	var gen_num := sur.size() - bonus_num
	
	return bonus_amount + gen_num * sur_bonus_am + bonus_num * sur_bonus_bonus_am

#func setup(game: GameMain = null) -> void:
	#super(game)
	#display_name = "Bonus"
	#description = "
		#Gives +%s score, gives additional +%s score for each adjacent block with a modifier. \
		#Blocks give extra +%s score if they have a Bonus modifier as well." % \
		#[str(bonus_amount), str(sur_bonus_am), str(sur_bonus_bonus_am)]
	#shader_path = "res://modifiers/shaders/bonus.gdshader"
	#mod_price = 800
