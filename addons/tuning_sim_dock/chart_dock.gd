@tool
extends Control

var _option: OptionButton
var _chart: Control
var _status: Label
var _export_button: Button

var _series: Dictionary = {}
var _current_key: String = ""

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

	_chart = Control.new()
	_chart.custom_minimum_size = Vector2(0, 200)
	_chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chart.draw.connect(_draw_chart)
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
	_series = TuningSim.compute_series(100)

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
		"x: %s-%s   y: %.3g to %.3g" % [str(min_x), str(max_x), min_y, max_y],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11)

func _on_export_pressed() -> void:
	_status.text = TuningSim.run()
