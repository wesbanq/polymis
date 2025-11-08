extends Modifier
class_name GlassModifier

@export var mult := 2
var triggered := false

func post_trigger() -> void:
	if not triggered:
		board.score_to_add *= mult
		triggered = true
		block.prototype_shape.shape_string[block.prototype_shape_idx].modifier.triggered = true

func setup(game: GameMain = null) -> void:
	super(game)
	#display_name = "Glass"
	#description = "
		#Multiplies the score by %dx. 
		#After scoring[color=#%s]removes this modifier from this polymino for the rest of the round[/color].
		#Will be destroyed if there are no block below it." % [mult, Enums.UI_COLORS.UI_DOWNSIDE_TEXT]
	shader_path = "res://modifiers/shaders/glass.gdshader" if not triggered else "res://modifiers/shaders/glass.gdshader"
	#mod_price = 6000
	
	_game.NewBoard.connect(func(_brd: Board) -> void:
		triggered = false
	)
