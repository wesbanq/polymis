extends Modifier
class_name GlassModifier

@export var mult := 2
#var a := false
#pattern for having global variable in modifierswdACFS ?ffsD>:{LGFA SFL:OJAHFE f\AF EF
var triggered := false:
	get: return get_from_prototype("triggered") if _copy else triggered
var local_triggered: bool
#funi gface >:{ >:} ;] :-}   8]

#  o /
# /|
# / \
#im going to fucking kill myself icant take this shit anymore it feels like every day is worse than the last and the hope of me ever somehow getting it under control and fixing my neverednig list of menatl problems without any outside help is ever fleeting id ont knmow how long i can keep going like this anymore
#LE EPIC MENTAL BREADKDOWN IN A COMMENT SO LE QUIRKY AND RANDUMMZZZZZZ LOL rawrOWO XddddddddddDD ~fluffles away~
#if ur reading ill kill you irl (threat) /srs
func post_trigger() -> void:
	#print(_copy, triggered, get_from_prototype("_copy"))
	if not local_triggered:
		board.score_to_add *= mult
		#triggered = true
		block.prototype_shape.shape_string[block.prototype_shape_idx].modifier.triggered = true

func setup(game: GameMain = null) -> void:
	super(game)
	local_triggered = triggered
	shader_path = "res://modifiers/shaders/glass.gdshader" if not local_triggered else ""
	if not _copy:
		_game.NewBoard.connect(func(_brd: Board) -> void:
			triggered = false
		)
