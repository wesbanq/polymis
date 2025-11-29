extends Node
class_name Hoverable

var top: String
var desc: String
var top_color: Color
var shop: bool
var f: Callable

var temp_hidden: bool = false:
	set(v): temp_hidden = v; if v and _hover: force_hide()
var _master: Variant
var _hover := false:
	set(v): 
		if _hover and not v: HoverManager.hide(self)
		if v: HoverManager.show(self, top, desc, top_color, shop)
		_hover = v

func force_hide() -> void:
	_hover = false
	#HoverManager.hide(self)

func _init(mst: Variant, chk_func: Callable, a: String, b: String, c: Color = Color(1, 1, 1), d: bool = false) -> void:
	_master = mst
	top = a
	desc = b
	top_color = c
	shop = d
	f = chk_func
	
	#print("top: %s end" % top)
	HoverManager.CheckHover.connect(func(pos: Vector2) -> void:
		if not _master or not f:
			free()
			push_error("%s godot is a genuine piece of dogshit game engine. i unironically wish i learned unity instead" % top)
		elif not temp_hidden: _hover = f.call(pos)
	)
