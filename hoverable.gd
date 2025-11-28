extends Node
class_name Hoverable

var top: String
var desc: String
var top_color: Color
var shop: bool
var f: Callable

var _master: Variant
var _hover := false:
	set(v): 
		if _hover and not v: HoverManager.hide(self)
		if v: HoverManager.show(self, top, desc, top_color, shop)
		_hover = v

func force_hide() -> void:
	HoverManager.hide(self)

func _init(mst: Variant, chk_func: Callable, a: String, b: String, c: Color, d: bool) -> void:
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
		else: _hover = f.call(pos)
	)
