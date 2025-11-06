extends Node
class_name Hover

const _hover_scene := preload("res://hover_window.tscn")

var _hover_ctrl := _hover_scene.instantiate()
var _hover_name_txt := _hover_ctrl.get_node("PanelContainer/VBoxContainer/PanelContainer/RichTextLabel")
var _hover_desc_txt := _hover_ctrl.get_node("PanelContainer/VBoxContainer/RichTextLabel")

var active := false:
	set(v): active = v; _hover_ctrl.visible = v

var current_name := "":
	set(v): current_name = v; _hover_name_txt.text = v
var current_desc := "":
	set(v): current_desc = v; _hover_desc_txt.text = v

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_hover_ctrl.global_position = event.position
		

func _ready() -> void:
	add_child(_hover_ctrl)
