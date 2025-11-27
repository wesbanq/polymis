extends HBoxContainer
class_name AbilUIElement

const _a_scene := preload("res://abil.tscn")
const _p_scene := preload("res://abilp.tscn")
var _scene: HBoxContainer

# Always
var _icon_ctrl: TextureRect
var _name_ctrl: RichTextLabel

# Active Abil Only
var _hotkey_ctrl: RichTextLabel
var _cost_ctrl: RichTextLabel

var active: bool = false:
	set = _set_active
var _a_name: String
var ability: Ability
var slot: int:
	set(v): if _hotkey_ctrl: _hotkey_ctrl.text = "[%d]" % v; slot = v#; print("slot%d"%slot)

var _hoverable: Hoverable

func _update_hoverable() -> void:
	if _hoverable: _hoverable.queue_free()
	_hoverable = Hoverable.new(
		self,
		_click_within_block,
		ability.display_name,
		ability.description,
		ability.display_name_color,
		false
	)
	add_child(_hoverable)

func _click_within_block(clk: Vector2) -> bool:
	@warning_ignore("integer_division")
	var right_x = _icon_ctrl.global_position.x
	@warning_ignore("integer_division")
	var left_x = _icon_ctrl.global_position.x + _icon_ctrl.size.x
	@warning_ignore("integer_division")
	var up_y = _icon_ctrl.global_position.y
	@warning_ignore("integer_division")
	var down_y = _icon_ctrl.global_position.y + _icon_ctrl.size.x
	
	return clk.x < left_x and clk.x > right_x and clk.y > up_y and clk.y < down_y

func _set_active(val: bool) -> void:
	active = val
	_icon_ctrl.material.set_shader_parameter("active", active)
	_name_ctrl.text = "[color=#%s]%s[/color]" % \
		[Enums.UI.NORMAL_TEXT.to_html(false) if active \
		else Enums.UI.UNAVAIL_TEXT.to_html(), _a_name]

func set_abil(abil: Ability) -> void:
	ability = abil
	_a_name = abil.display_name
	
	_name_ctrl.text = "[color=#%s]%s[/color]" % [Enums.UI.NORMAL_TEXT.to_html(false), _a_name]
	_icon_ctrl.texture = load(abil.image_path)
	
	if abil is AbilityActive:
		_cost_ctrl.text = "[color=#%s]%d%%[/color]" % [Enums.UI.SP.to_html(false), abil.sp_cost]
		_icon_ctrl.material.set_shader_parameter("tint", Enums.UI.ACTIVE_ABIL_ICON_A)
		_icon_ctrl.material.set_shader_parameter("otint", Enums.UI.INACTIVE_ABIL_ICON_A)
	else:
		_icon_ctrl.material.set_shader_parameter("tint", Enums.UI.ACTIVE_ABIL_ICON_P)
		_icon_ctrl.material.set_shader_parameter("otint", Enums.UI.INACTIVE_ABIL_ICON_P)
	_set_active(active)
	_update_hoverable()

func _init(slt: int, abil: Ability = null) -> void:
	if abil is AbilityPassive:
		_scene = _p_scene.instantiate()
	else:
		_scene = _a_scene.instantiate()
		_cost_ctrl = _scene.get_node("VBoxContainer/AbilCost")
		_hotkey_ctrl = _scene.get_node("Hotkey")
	
	slot = slt
	_icon_ctrl = _scene.get_node("AbilIcon")
	_name_ctrl = _scene.get_node("VBoxContainer/AbilName")
	
	active = false
	add_child(_scene)
	if abil != null: set_abil(abil)
