extends Control
class_name AbilityControl

signal ActivateAbility(slot: int)
signal UpdateBar(new: int)

const _main_scene := preload("res://abil_ui.tscn")

@onready var _game: GameMain = get_parent().get_parent()
@onready var _main_ctrl := _main_scene.instantiate()

@warning_ignore("unused_private_class_variable")
@onready var _sp_bar_ctrl := _main_ctrl.get_node("HBoxContainer/Bar")
@onready var _sp_bar_lbl := _main_ctrl.get_node("HBoxContainer/Bar/RichTextLabel")
@onready var _sp_bar_blks := _sp_bar_ctrl.get_node("Control/VBoxContainer")
@onready var _a_abils_ctrl := _main_ctrl.get_node("HBoxContainer/VBoxContainer/ActiveAbils")
@warning_ignore("unused_private_class_variable")
@onready var _p_abils_ctrl := _main_ctrl.get_node("HBoxContainer/VBoxContainer/PassiveAbils")
@onready var _sp_bar_blk_prefab := _main_ctrl.get_node("HBoxContainer/Bar/TextureRect")

@onready var _board_ctrl := _main_ctrl.get_node("HBoxContainer/VBoxContainer/HBoxContainer")
var next_board: Board
var hold_board: Board

var held_pm: PolyminoShape
var next_pms: Array[Polymino]

var _a_abils_arr: Array[AbilUIElement] = []
var _p_abils_arr: Array[AbilUIElement] = []

const _sp_bar_txt := "S\nP\n:\n%s\n%%"

var block_size_px: int
@warning_ignore("unused_private_class_variable")
var _progress: int:
	set(v): _progress = v; _update_bar()

@warning_ignore("unused_parameter")
func set_abils_from_arr(abils_a: Array[AbilityActive], abils_p: Array[AbilityPassive], bsp: int = 32) -> void:
	#assumes len of abils never changes
	#change when abil len becomes changeable mid gameplay
	for i in abils_a.size():
		#if abils_a[i] is AbilityActive:
			_a_abils_arr.append(AbilUIElement.new(i+1, abils_a[i]))
			_a_abils_ctrl.add_child(_a_abils_arr[-1])
	
	#for i in abils_p.size():
		##if abils_p[i] is AbilityPassive:
			#_p_abils_arr.append(AbilUIElement.new(i+1, abils_p[i]))
			#_p_abils_ctrl.add_child(_p_abils_arr[-1])
	
	block_size_px = bsp

func set_abil_at(slot: int, abil: Ability) -> void:
	if abil is AbilityActive:
		if _a_abils_arr[slot]:
			_a_abils_arr[slot].set_abil(abil)
		else:
			_a_abils_arr.insert(slot, AbilUIElement.new(slot, abil))

func _update_bar() -> void:
	var prog := float(_progress)/100 * _sp_bar_blks.get_child_count()
	#print("%f %f %d %d" % [prog, float(_progress), _sp_bar_blks.get_child_count(), _progress])
	
	_sp_bar_lbl.text = _sp_bar_txt % "\n".join(str(clampi(_progress, 0, 100)).split())
	
	var c := _sp_bar_blks.get_children()
	c.reverse()
	for blk in c:
		if prog > 1:
			blk.material.set_shader_parameter("progress", 0)
			prog -= 1
		elif prog > 0:
			blk.material.set_shader_parameter("progress", prog)
			prog -= 1
		else:
			blk.material.set_shader_parameter("progress", 1)

@warning_ignore("unused_parameter")
func _rescale_bar(brd: Board = null) -> void:
	@warning_ignore("incompatible_ternary")
	var cb: Board = _game.board if _game.board else _game.shop if _game.shop else null
	if cb:
		for child in _sp_bar_blks.get_children(): child.queue_free()
		_sp_bar_blks.get_parent().custom_minimum_size = Vector2(cb.grid_size_px, 0)
		for i in cb.height:
			var new_blk: TextureRect = _sp_bar_blk_prefab.duplicate()
			new_blk.material = _sp_bar_blk_prefab.material.duplicate_deep()
			new_blk.material.set_shader_parameter("tint", Enums.UI.SP)
			new_blk.material.set_shader_parameter("otint", Enums.UI.UNAVAIL_TEXT)
			new_blk.visible = true
			_sp_bar_blks.add_child(new_blk)
		#_sp_bar_blks.position = Vector2(-cb.grid_size_px, 0)
	else:
		push_error("no board to inherit arguments from")
	_update_bar()

func _set_active(slot: int, abil_type_active: bool) -> void:
	#assume abils cant deactivate
	if abil_type_active:
		_a_abils_arr[slot].active = true
	else:
		_p_abils_arr[slot].active = true

@warning_ignore("shadowed_variable_base_class")
func _changed_attr_wrapper(name: String, val: Variant) -> void:
	match name:
		"special_points":
			_progress = val
		"height":
			_rescale_bar()
		"grid_size_px":
			next_board.grid_size_px = val
			hold_board.grid_size_px = val
			_rescale_bar()

func add_to_next(shape: PolyminoShape) -> void:
	next_pms.pop_front()
	next_pms.append(next_board._add_polymino(shape))
	

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_game.BoardChangedAttr.connect(_changed_attr_wrapper)
	_game.NewBoard.connect(_rescale_bar)
	UpdateBar.connect(_update_bar)
	ActivateAbility.connect(_set_active)
	
	add_child(_main_ctrl)
	
	hold_board = Board.new(4, 4)
	next_board = Board.new(_game.next_size * 4 + _game.next_size - 1, 4)
	next_pms.resize(_game.next_size)
	
	_board_ctrl.add_child(next_board)
	_board_ctrl.add_child(hold_board)
