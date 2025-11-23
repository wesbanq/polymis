extends Node

signal CheckHover(pos: Vector2)

const _hover_scene := preload("res://hover_window.tscn")

var _hover_ctrl := _hover_scene.instantiate()
var _hover_top_txt: RichTextLabel = _hover_ctrl.get_node("PanelContainer/VBoxContainer/PanelContainer/RichTextLabel")
var _hover_top_bg: PanelContainer = _hover_ctrl.get_node("PanelContainer/VBoxContainer/PanelContainer/")
var _hover_desc_txt: RichTextLabel = _hover_ctrl.get_node("PanelContainer/VBoxContainer/RichTextLabel")

var _currently_hovering: Variant = null

func show(who: Variant, top_name: String, desc_txt: String, top_color: Color, shop: bool) -> void:
	if who == _currently_hovering: return
	_currently_hovering = who
	
	_hover_top_bg.get_theme_stylebox("panel").bg_color = top_color
	_hover_top_txt.text = top_name
	_hover_desc_txt.text = desc_txt + ("BUYABLE" if shop else "")
	_hover_ctrl.visible = true

func hide(who: Variant) -> void:
	if who != _currently_hovering: return
	_hover_ctrl.visible = false
	_currently_hovering = null

func _ready() -> void:
	get_node("/root").add_child.call_deferred(_hover_ctrl)
	_hover_ctrl.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var world_pos: Vector2 = (get_viewport().get_screen_transform() * get_viewport().get_canvas_transform()).affine_inverse() * event.position
		_hover_ctrl.position = world_pos
		CheckHover.emit(world_pos)
