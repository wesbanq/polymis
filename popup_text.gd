extends Label
class_name ScorePopup

const TEXT_DISTANCE := 64

var tween: Tween = null

static func create(
		parent: Node, 
		number: int = 0, 
		number_s: float = 0.2,
		scale_: float = 1.0, 
		offset_y: float = 0.0,
		offset_x: float = 0.0
	) -> ScorePopup:
	var txt := ScorePopup.new()
	txt.text = str(number)
	txt.text = ("+" if number > 0 else "") + str(number)
	txt.z_index = 101
	txt.theme = preload("res://text.tres")
	#txt.scale = Vector2(scale_, scale_)
	txt.add_theme_font_size_override("", txt.get_theme_default_font_size() * scale_)
	parent.add_child(txt)
	txt.position -= Vector2(txt.size.x / 2 + offset_x, offset_y)
	txt.tween = txt.create_tween()
	txt.tween.tween_property(txt, "position", txt.position + Vector2(0, -TEXT_DISTANCE), number_s)
	txt.tween.tween_callback(txt.queue_free)
	txt.tween.play()

	return txt
