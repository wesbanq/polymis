extends Modifier
class_name GlassModifier

@export var triggered := false

func post_trigger() -> void:
	if not triggered:
		board.

func _init() -> void:
	display_name = "Glass"
	description = "
		Multiplies the score by 2x. 
		After scoring[color=#ff0000]removes this modifier from this polymino for the rest of the round[/color].
		Will be destroyed if there are no block below it."
	shader_path = "res://modifiers/shaders/glass.gdshader" if not triggered else "res://modifiers/shaders/glass.gdshader"
	mod_price = 6000
