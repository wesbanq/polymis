@tool
extends Control

var _option: OptionButton
var _chart: Control
var _status: Label
var _export_button: Button

const POLL_INTERVAL := 0.25

var _series: Dictionary = {}
var _current_key: String = ""
var _poll_accum := 0.0

# current value of each formula's extra (non-swept) argument -- see TuningSim.EXTRA_ARGS.
# one slider per entry is built in _ready(); keys/ranges/defaults all come from there so this
# dock never needs its own copy of what the arguments are or what's reasonable for them
var _arg_values: Dictionary = {}
var _arg_labels: Dictionary = {}

# local-to-_chart pixel x of the mouse, or -1 when not hovering; read back in _draw_chart()
var _hover_x: float = -1.0

# every Resource we've hooked .changed on, so _reload_watched() can cleanly disconnect
# before reconnecting (also covers Curve sub-resources like fall_speed/flash_curve, since
# editing a curve control point emits `changed` on the Curve, not necessarily on the
# GameTuning/EffectTuning resource that holds it)
var _watched: Array[Resource] = []

func _ready() -> void:
	name = "Tuning Sim"
	custom_minimum_size = Vector2(260, 320)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	_option = OptionButton.new()
	_option.item_selected.connect(_on_option_selected)
	vbox.add_child(_option)

	for arg_name in TuningSim.EXTRA_ARGS:
		vbox.add_child(_build_arg_slider(arg_name, TuningSim.EXTRA_ARGS[arg_name]))

	_chart = Control.new()
	_chart.custom_minimum_size = Vector2(0, 200)
	_chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chart.mouse_filter = Control.MOUSE_FILTER_STOP
	_chart.draw.connect(_draw_chart)
	_chart.gui_input.connect(_on_chart_gui_input)
	_chart.mouse_exited.connect(_on_chart_mouse_exited)
	vbox.add_child(_chart)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_status)

	_export_button = Button.new()
	_export_button.text = "Export CSVs (res://tuning_sim/)"
	_export_button.pressed.connect(_on_export_pressed)
	vbox.add_child(_export_button)

	_reload_watched()
	_refresh_series()
	_populate_options()
	set_process(true)

## Resource.changed doesn't reliably fire for a generic property edit on a plain custom
## Resource in the inspector (that behavior seems to be specific to built-in types like Curve/
## Material, not something the generic inspector guarantees for arbitrary Resource subclasses)
## -- confirmed by this dock not updating in practice. Polling is slower to react (up to
## POLL_INTERVAL) but can't silently fail to notice a change the way the signal did.
func _process(delta: float) -> void:
	_poll_accum += delta
	if _poll_accum < POLL_INTERVAL:
		return
	_poll_accum = 0.0
	_refresh_series()
	if _chart:
		_chart.queue_redraw()

func _build_arg_slider(arg_name: String, range_def: Dictionary) -> Control:
	_arg_values[arg_name] = range_def["default"]

	var row := HBoxContainer.new()

	var label := Label.new()
	label.custom_minimum_size = Vector2(70, 0)
	label.text = "%s: %s" % [arg_name, str(range_def["default"])]
	_arg_labels[arg_name] = label
	row.add_child(label)

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = range_def["min"]
	slider.max_value = range_def["max"]
	slider.step = 1
	slider.value = range_def["default"]
	slider.value_changed.connect(func(v: float) -> void: _on_arg_changed(arg_name, v))
	row.add_child(slider)

	return row

func _on_arg_changed(arg_name: String, value: float) -> void:
	_arg_values[arg_name] = int(value)
	_arg_labels[arg_name].text = "%s: %d" % [arg_name, int(value)]
	_refresh_series()
	if _chart:
		_chart.queue_redraw()

func _reload_watched() -> void:
	for r in _watched:
		if is_instance_valid(r) and r.changed.is_connected(_on_tuning_changed):
			r.changed.disconnect(_on_tuning_changed)
	_watched.clear()

	var game_t := TuningSim.load_game_tuning()
	var shop_t := TuningSim.load_shop_tuning()
	var effects_t := TuningSim.load_effects_tuning()
	_watched.append_array([game_t, shop_t, effects_t])
	# Curve edits (dragging a control point) emit `changed` on the Curve itself, not
	# necessarily on the Tuning resource holding it -- watch those directly too
	if game_t.fall_speed:
		_watched.append(game_t.fall_speed)
	if effects_t.flash_curve:
		_watched.append(effects_t.flash_curve)

	for r in _watched:
		if not r.changed.is_connected(_on_tuning_changed):
			r.changed.connect(_on_tuning_changed)

func _on_tuning_changed() -> void:
	# a changed Tuning resource could mean a Curve got swapped out for a different one,
	# so re-gather what to watch, not just what to redraw
	_reload_watched()
	_refresh_series()
	if _chart:
		_chart.queue_redraw()
	if _status:
		_status.text = "updated %s" % Time.get_time_string_from_system()

func _refresh_series() -> void:
	_series = TuningSim.compute_series(100, _arg_values["width"], _arg_values["current"], _arg_values["abil_tier"])

func _populate_options() -> void:
	if not _option:
		return
	var prev := _current_key
	_option.clear()
	var idx := 0
	var restore := 0
	for key in _series.keys():
		_option.add_item(key)
		if key == prev:
			restore = idx
		idx += 1
	if _series.size() > 0:
		_option.select(restore)
		_current_key = _option.get_item_text(restore)

func _on_option_selected(idx: int) -> void:
	_current_key = _option.get_item_text(idx)
	_chart.queue_redraw()

func _on_chart_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover_x = event.position.x
		_chart.queue_redraw()

func _on_chart_mouse_exited() -> void:
	_hover_x = -1.0
	_chart.queue_redraw()

## compact display for values ranging from ~0.05 (falling_speed) to ~999999 (prices) --
## GDScript's % string formatting has no %g ("shortest readable" float) specifier, so this
## picks a fixed-decimal format by magnitude instead
static func _fmt_num(v: float) -> String:
	if absf(v) >= 1000.0:
		return "%.0f" % v
	elif absf(v) >= 1.0:
		return "%.2f" % v
	return "%.4f" % v

func _draw_chart() -> void:
	if _current_key == "" or not _series.has(_current_key):
		return
	var points: Array = _series[_current_key]
	if points.is_empty():
		return

	var rect_size := _chart.size
	_chart.draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.5, 0.5, 0.5, 0.08))

	var min_x: float = points[0].x
	var max_x: float = points[-1].x
	var min_y: float = points[0].y
	var max_y: float = points[0].y
	for p in points:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	if is_equal_approx(max_y, min_y):
		max_y += 1.0
	if is_equal_approx(max_x, min_x):
		max_x += 1.0

	var margin := 28.0
	var plot_w: float = rect_size.x - margin * 2
	var plot_h: float = rect_size.y - margin * 2

	var poly := PackedVector2Array()
	for p in points:
		var nx: float = margin + (p.x - min_x) / (max_x - min_x) * plot_w
		var ny: float = margin + plot_h - (p.y - min_y) / (max_y - min_y) * plot_h
		poly.append(Vector2(nx, ny))

	if poly.size() >= 2:
		_chart.draw_polyline(poly, Color(0.35, 0.7, 1.0), 2.0, true)

	var font := ThemeDB.fallback_font
	_chart.draw_string(font, Vector2(4, 14), _current_key, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	_chart.draw_string(font, Vector2(4, rect_size.y - 6),
		"x: %s-%s   y: %s to %s" % [_fmt_num(min_x), _fmt_num(max_x), _fmt_num(min_y), _fmt_num(max_y)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11)

	# hover readout: map the cursor's pixel x back to a data point and show its exact value.
	# points are always consecutive integer x steps (round_num or clear-step), so the nearest
	# index is a direct round-trip through the same x-axis scale used to build `poly` above
	if _hover_x >= 0.0 and _hover_x >= margin and _hover_x <= rect_size.x - margin:
		var data_x: float = min_x + (_hover_x - margin) / plot_w * (max_x - min_x)
		var idx: int = clampi(roundi(data_x - points[0].x), 0, points.size() - 1)
		var pt: Vector2 = points[idx]
		var hx: float = margin + (pt.x - min_x) / (max_x - min_x) * plot_w
		var hy: float = margin + plot_h - (pt.y - min_y) / (max_y - min_y) * plot_h

		_chart.draw_line(Vector2(hx, margin), Vector2(hx, margin + plot_h), Color(1, 1, 1, 0.3), 1.0)
		_chart.draw_circle(Vector2(hx, hy), 3.5, Color(1, 0.9, 0.2))

		var label := "x=%s  y=%s" % [_fmt_num(pt.x), _fmt_num(pt.y)]
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		var label_pos := Vector2(hx + 6, hy - 6)
		if label_pos.x + label_size.x > rect_size.x:
			label_pos.x = hx - 6 - label_size.x
		if label_pos.y - label_size.y < 0:
			label_pos.y = hy + label_size.y + 6
		_chart.draw_rect(Rect2(label_pos + Vector2(-2, -label_size.y), label_size + Vector2(4, 4)), Color(0, 0, 0, 0.6))
		_chart.draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.2))

func _on_export_pressed() -> void:
	_status.text = TuningSim.run(120, _arg_values["width"], _arg_values["current"], _arg_values["abil_tier"])
