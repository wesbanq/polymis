extends Node
class_name Hoverable

var top: String
var desc: String
var top_color: Color
var shop: bool

var _master: Variant
var _hover := false:
	set(v): 
		if _hover and not v: HoverManager.hide(self)
		if v: HoverManager.show(self, top, desc, top_color, shop)
		_hover = v

func _init(mst: Variant, chk_func: Callable, a: String, b: String, c: Color, d: bool) -> void:
	_master = mst
	top = a
	desc = b
	top_color = c
	shop = d
	
	HoverManager.CheckHover.connect(func(pos: Vector2) -> void:
		_hover = chk_func.call(pos)
	)
