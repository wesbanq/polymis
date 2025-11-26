extends Resource
class_name BlockInfo

@export var color: Color = Enums.COLORS.WHITE
#@export var modifier: Modifier = null
@export var modifier: String = ""
@export var score_amount: int = 100

func _init(c: Color = color, m: String = modifier, s: int = score_amount) -> void:
	if modifier.simplify_path().get_base_dir() == Enums.MODIFIER_PATH:
		color = c
		modifier = m
		score_amount = s
