@tool
extends Control

## Two-handle range slider -- Godot has no built-in one. Left handle sets the low end of the
## range, right handle the high end; they can meet but never cross.

signal range_changed(low: int, high: int)

const HANDLE_R := 6.0
const PAD := 8.0

var min_limit := 0
var max_limit := 100
var low := 0
var high := 100

var _drag := -1  # -1 = none, 0 = low handle, 1 = high handle

func _init() -> void:
	custom_minimum_size = Vector2(0, 22)
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup(p_min: int, p_max: int, p_low: int, p_high: int) -> void:
	min_limit = p_min
	max_limit = maxi(p_max, p_min + 1)
	low = clampi(p_low, min_limit, max_limit)
	high = clampi(p_high, low, max_limit)
	queue_redraw()

func set_low(v: int) -> void:
	low = clampi(v, min_limit, high)
	queue_redraw()

func set_high(v: int) -> void:
	high = clampi(v, low, max_limit)
	queue_redraw()

func _value_to_x(v: int) -> float:
	var t := float(v - min_limit) / float(max_limit - min_limit)
	return PAD + t * maxf(1.0, size.x - PAD * 2.0)

func _x_to_value(x: float) -> int:
	var t := clampf((x - PAD) / maxf(1.0, size.x - PAD * 2.0), 0.0, 1.0)
	return roundi(min_limit + t * float(max_limit - min_limit))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var lx := _value_to_x(low)
			var hx := _value_to_x(high)
			# when both handles sit on the same spot, pick by which side of them was clicked
			# so neither handle can get permanently stuck under the other
			if is_equal_approx(lx, hx):
				_drag = 0 if event.position.x < lx else 1
			else:
				_drag = 0 if absf(event.position.x - lx) <= absf(event.position.x - hx) else 1
			_apply_drag(event.position.x)
		else:
			_drag = -1
	elif event is InputEventMouseMotion and _drag != -1:
		_apply_drag(event.position.x)

func _apply_drag(x: float) -> void:
	var v := _x_to_value(x)
	if _drag == 0:
		low = clampi(v, min_limit, high)
	else:
		high = clampi(v, low, max_limit)
	queue_redraw()
	range_changed.emit(low, high)

func _draw() -> void:
	var mid := size.y * 0.5
	draw_line(Vector2(PAD, mid), Vector2(size.x - PAD, mid), Color(1, 1, 1, 0.15), 3.0)

	var lx := _value_to_x(low)
	var hx := _value_to_x(high)
	draw_line(Vector2(lx, mid), Vector2(hx, mid), Color(0.35, 0.7, 1.0), 3.0)
	draw_circle(Vector2(lx, mid), HANDLE_R, Color(0.85, 0.85, 0.85))
	draw_circle(Vector2(hx, mid), HANDLE_R, Color(0.85, 0.85, 0.85))
