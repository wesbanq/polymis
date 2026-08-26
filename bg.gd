extends Control

@onready var bg := $Background
@onready var fg := $Foreground

var active: bool: 
	get: return _active
var _active := true

var _bg_calc_mult: float
@export var bg_dist_mult: float:
	set(v):
		bg_dist_mult = v
		_bg_calc_mult = asin(1 / sqrt((2 * v)**2 + 1))
		_update_scale()
		_update_speed()

@export var speed: float:
	set(v): 
		speed = v
		_update_speed()
@export var direction: Vector2:
	set(v):
		direction = v
		_update_dir()
@export var bg_pos_offset: Vector2:
	set(v):
		bg_pos_offset = v
		_update_offset()
@export var grid_color: Color:
	set(v):
		grid_color = v
		_update_color()

@export var bg_color_darkened: float:
	set(v):
		bg_color_darkened = v
		_update_color()
@export var bg_transparency: float:
	set(v):
		bg_transparency = v
		_update_color()

@export var bg_grid_scale_mult: float:
	set(v):
		bg_grid_scale_mult = v
		_update_scale()
@export var grid_scale: float:
	set(v):
		grid_scale = v
		_update_scale()

var _paused: bool = false
var _saved_time: float = 0.

func _update_scale() -> void:
	if is_node_ready():
		bg.material.set_shader_parameter("scale", 
			Vector2(grid_scale * _bg_calc_mult * bg_grid_scale_mult, 
			grid_scale * _bg_calc_mult * bg_grid_scale_mult))
		fg.material.set_shader_parameter("scale", Vector2(grid_scale, grid_scale))

func _update_dir() -> void:
	if is_node_ready():
		bg.material.set_shader_parameter("direction", direction)
		fg.material.set_shader_parameter("direction", direction)

func _update_speed() -> void:
	if is_node_ready():
		bg.material.set_shader_parameter("speed", speed * _bg_calc_mult)
		fg.material.set_shader_parameter("speed", speed)

func _update_color() -> void:
	if is_node_ready():
		var trans := Color(1, 1, 1, bg_transparency)
		bg.material.set_shader_parameter("tint", grid_color.darkened(bg_color_darkened) * trans)
		fg.material.set_shader_parameter("tint", grid_color * trans)

func _update_offset() -> void:
	if is_node_ready():
		bg.material.set_shader_parameter("offset", bg_pos_offset)

func activate() -> void:
	if _active: return
	_active = true
	show()

func unactivate() -> void:
	if not _active: return
	_active = false
	hide()

#func tgl_pause() -> void:
	#_paused = not _paused
	#if _paused:
		#bg.material.set_shader_parameter("saved_time", _saved_time)
		#fg.material.set_shader_parameter("saved_time", _saved_time)
	#else:
		#bg.material.set_shader_parameter("saved_time", 0.)
		#fg.material.set_shader_parameter("saved_time", 0.)

func _ready() -> void:
	unactivate()
	_update_color()
	_update_dir()
	_update_speed()
	_update_offset()
	_update_scale()
