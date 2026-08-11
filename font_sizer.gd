extends Node

@onready var style: Theme = load("res://text.tres")
@onready var _size: int = style.default_font_size

@onready var style2: Theme = load("res://abil_text.tres")
@onready var _size2: int = style2.default_font_size

static var _viewport: Viewport
const _BASE_RECT := Vector2i(1152, 648)

static func _get_new_size(size: int) -> float:
	return _viewport.get_visible_rect().size.y / _BASE_RECT.y * size

func _ready() -> void:
	_viewport = get_viewport()
	_viewport.size_changed.connect(func():
		style.default_font_size = _get_new_size(_size)
		style2.default_font_size = _get_new_size(_size2)
	)
