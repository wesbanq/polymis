extends Resource
class_name Ability

@export var display_name: String = "Placeholder"
@export var display_name_color: Color = Color(1, 1, 1)
@export var description: String = "im going to kill myself"
@export var image_path: String = "res://abils/active/icons/gen_abil.png"

var game: GameMain

func _init(gme: GameMain) -> void:
	game = gme
