@tool
extends Control

const RangeSlider := preload("res://addons/tuning_sim_dock/range_slider.gd")

const POLL_INTERVAL := 0.25

var _option: OptionButton
var _args_box: VBoxContainer
var _domain_label: Label
# deliberately untyped: statically typing this as Control would make GDScript reject the
# RangeSlider-specific members (setup/set_low/set_high/range_changed) at parse time
var _domain_slider
var _domain_low_spin: SpinBox
var _domain_high_spin: SpinBox
var _chart: Control
var _status: Label
var _export_button: Button

var _current_key: String = ""
var _x_arg: String = "round"          # which argument is swept across the chart's x-axis
var _domain_low: int = 1
var _domain_high: int = 120
var _points: Array[Vector2] = []
var _poll_accum := 0.0

# held-fixed value of every argument (the ones not currently being swept), keyed as in
# TuningSim.ARGS -- only the ones the selected formula actually takes get a row in the UI
var _arg_values: Dictionary = {}

# local-to-_chart pixel x of the mouse, or -1 when not hovering; read back in _draw_chart()
var _hover_x: float = -1.0

# every Resource we've hooked .changed on, so _reload_watched() can cleanly disconnect
# before reconnecting
var _watched: Array[Resource] = []

func _ready() -> void:
	name = "Tuning Sim"
	custom_minimum_size = Vector2(300, 360)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	for arg_name in TuningSim.ARGS:
		_arg_values[arg_name] = TuningSim.ARGS[arg_name]["default"]

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	_option = OptionButton.new()
	_option.item_selected.connect(_on_option_selected)
	vbox.add_child(_option)

	_args_box = VBoxContainer.new()
	vbox.add_child(_args_box)

	_domain_label = Label.new()
	vbox.add_child(_domain_label)

	_domain_slider = RangeSlider.new()
	_domain_slider.range_changed.connect(_on_domain_slider_changed)
	vbox.add_child(_domain_slider)

	var domain_spins := HBoxContainer.new()
	_domain_low_spin = SpinBox.new()
	_domain_low_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_domain_low_spin.value_changed.connect(_on_domain_low_spin_changed)
	domain_spins.add_child(_domain_low_spin)
	_domain_high_spin = SpinBox.new()
	_domain_high_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_domain_high_spin.value_changed.connect(_on_domain_high_spin_changed)
	domain_spins.add_child(_domain_high_spin)
	vbox.add_child(domain_spins)

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
	_populate_options()
	_select_series(_option.get_item_text(0) if _option.item_count > 0 else "")
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
	_refresh()

# --- series selection -------------------------------------------------------------------

func _populate_options() -> void:
	_option.clear()
	for series_name in TuningSim.SERIES_DEFS:
		_option.add_item(series_name)
	if _option.item_count > 0:
		_option.select(0)

func _on_option_selected(idx: int) -> void:
	_select_series(_option.get_item_text(idx))

func _select_series(series_name: String) -> void:
	if series_name == "" or not TuningSim.SERIES_DEFS.has(series_name):
		return
	_current_key = series_name
	_set_x_arg(TuningSim.SERIES_DEFS[series_name]["x"])

## switches which argument the chart sweeps, resetting the domain to that argument's natural
## range (which for "step" depends on the current width and last_flash_line)
func _set_x_arg(arg_name: String) -> void:
	_x_arg = arg_name
	var d := TuningSim.default_domain(arg_name, _arg_values)
	_domain_low = d.x
	_domain_high = d.y
	_sync_domain_controls()
	_rebuild_arg_rows()
	_refresh()

# --- argument rows ----------------------------------------------------------------------

func _rebuild_arg_rows() -> void:
	for child in _args_box.get_children():
		_args_box.remove_child(child)
		child.queue_free()

	if not TuningSim.SERIES_DEFS.has(_current_key):
		return
	for arg_name in TuningSim.SERIES_DEFS[_current_key]["args"]:
		_args_box.add_child(_build_arg_row(arg_name))

func _build_arg_row(arg_name: String) -> Control:
	var def: Dictionary = TuningSim.ARGS[arg_name]
	var is_x: bool = arg_name == _x_arg

	var row := HBoxContainer.new()

	# the little button that promotes this argument to the x-axis
	var x_button := Button.new()
	x_button.text = "x"
	x_button.toggle_mode = true
	x_button.button_pressed = is_x
	x_button.custom_minimum_size = Vector2(24, 0)
	x_button.tooltip_text = "Sweep %s across the x-axis" % arg_name
	# rebuilding these rows frees the very button emitting this signal, so defer it
	x_button.pressed.connect(func() -> void: _set_x_arg.call_deferred(arg_name))
	row.add_child(x_button)

	var label := Label.new()
	label.custom_minimum_size = Vector2(64, 0)
	label.text = arg_name
	row.add_child(label)

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.min_value = def["min"]
	slider.max_value = def["max"]
	slider.step = 1
	slider.value = _arg_values[arg_name]
	slider.editable = not is_x
	row.add_child(slider)

	var spin := SpinBox.new()
	spin.custom_minimum_size = Vector2(58, 0)
	spin.min_value = def["min"]
	spin.max_value = def["max"]
	spin.step = 1
	spin.value = _arg_values[arg_name]
	spin.editable = not is_x
	row.add_child(spin)

	# keep slider and number box mirrored without either re-triggering the other
	slider.value_changed.connect(func(v: float) -> void:
		spin.set_value_no_signal(v)
		_on_arg_changed(arg_name, v))
	spin.value_changed.connect(func(v: float) -> void:
		slider.set_value_no_signal(v)
		_on_arg_changed(arg_name, v))

	return row

func _on_arg_changed(arg_name: String, value: float) -> void:
	_arg_values[arg_name] = int(value)
	# the step axis's length is derived from width, so changing width can invalidate the domain
	if _x_arg == "step" and arg_name == "width":
		var d := TuningSim.default_domain("step", _arg_values)
		_domain_low = d.x
		_domain_high = d.y
		_sync_domain_controls()
	_refresh()

# --- domain -----------------------------------------------------------------------------

func _sync_domain_controls() -> void:
	var def: Dictionary = TuningSim.ARGS[_x_arg]
	_domain_label.text = "domain: %s" % _x_arg
	_domain_slider.setup(int(def["min"]), int(def["max"]), _domain_low, _domain_high)

	_domain_low_spin.min_value = def["min"]
	_domain_low_spin.max_value = def["max"]
	_domain_low_spin.set_value_no_signal(_domain_low)
	_domain_high_spin.min_value = def["min"]
	_domain_high_spin.max_value = def["max"]
	_domain_high_spin.set_value_no_signal(_domain_high)

func _on_domain_slider_changed(low: int, high: int) -> void:
	_domain_low = low
	_domain_high = high
	_domain_low_spin.set_value_no_signal(low)
	_domain_high_spin.set_value_no_signal(high)
	_refresh()

func _on_domain_low_spin_changed(v: float) -> void:
	_domain_low = mini(int(v), _domain_high)
	_domain_low_spin.set_value_no_signal(_domain_low)
	_domain_slider.set_low(_domain_low)
	_refresh()

func _on_domain_high_spin_changed(v: float) -> void:
	_domain_high = maxi(int(v), _domain_low)
	_domain_high_spin.set_value_no_signal(_domain_high)
	_domain_slider.set_high(_domain_high)
	_refresh()

# --- data + resource watching -------------------------------------------------------------

func _refresh() -> void:
	if _current_key == "":
		return
	_points = TuningSim.compute_one(_current_key, _x_arg, _domain_low, _domain_high, _arg_values)
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
	if game_t.fall_speed:
		_watched.append(game_t.fall_speed)
	if effects_t.flash_curve:
		_watched.append(effects_t.flash_curve)

	for r in _watched:
		if not r.changed.is_connected(_on_tuning_changed):
			r.changed.connect(_on_tuning_changed)

func _on_tuning_changed() -> void:
	_reload_watched()
	_refresh()
	if _status:
		_status.text = "updated %s" % Time.get_time_string_from_system()

# --- chart --------------------------------------------------------------------------------

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

## x values are always whole argument steps (round 7, width 10, ...), so they read better
## without the decimals _fmt_num() gives y values
static func _fmt_x(v: float) -> String:
	return str(int(v))

func _draw_chart() -> void:
	if _points.is_empty():
		return

	var rect_size := _chart.size
	_chart.draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.5, 0.5, 0.5, 0.08))

	var min_x: float = _points[0].x
	var max_x: float = _points[-1].x
	var min_y: float = _points[0].y
	var max_y: float = _points[0].y
	for p in _points:
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
	for p in _points:
		var nx: float = margin + (p.x - min_x) / (max_x - min_x) * plot_w
		var ny: float = margin + plot_h - (p.y - min_y) / (max_y - min_y) * plot_h
		poly.append(Vector2(nx, ny))

	if poly.size() >= 2:
		_chart.draw_polyline(poly, Color(0.35, 0.7, 1.0), 2.0, true)
	elif poly.size() == 1:
		_chart.draw_circle(poly[0], 3.0, Color(0.35, 0.7, 1.0))

	var font := ThemeDB.fallback_font
	_chart.draw_string(font, Vector2(4, 14), _current_key, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	_chart.draw_string(font, Vector2(4, rect_size.y - 6),
		"%s: %s-%s   y: %s to %s" % [_x_arg, _fmt_x(min_x), _fmt_x(max_x), _fmt_num(min_y), _fmt_num(max_y)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11)

	# hover readout: map the cursor's pixel x back to a data point and show its exact value.
	# points are always consecutive integer x steps, so the nearest index is a direct round-trip
	# through the same x-axis scale used to build `poly` above
	if _hover_x >= 0.0 and _hover_x >= margin and _hover_x <= rect_size.x - margin:
		var data_x: float = min_x + (_hover_x - margin) / plot_w * (max_x - min_x)
		var idx: int = clampi(roundi(data_x - _points[0].x), 0, _points.size() - 1)
		var pt: Vector2 = _points[idx]
		var hx: float = margin + (pt.x - min_x) / (max_x - min_x) * plot_w
		var hy: float = margin + plot_h - (pt.y - min_y) / (max_y - min_y) * plot_h

		_chart.draw_line(Vector2(hx, margin), Vector2(hx, margin + plot_h), Color(1, 1, 1, 0.3), 1.0)
		_chart.draw_circle(Vector2(hx, hy), 3.5, Color(1, 0.9, 0.2))

		var label := "%s=%s  y=%s" % [_x_arg, _fmt_x(pt.x), _fmt_num(pt.y)]
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
