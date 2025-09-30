extends Resource
class_name BlockInfo

@export var color: Color = Enums.COLORS.WHITE
@export var modifier: Modifier = null
@export var score_amount: int = 100

func _init(c: Color = color, m: Modifier = modifier, s: int = score_amount) -> void:
	color = c
	modifier = m
	score_amount = s
