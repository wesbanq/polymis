extends Control
class_name ScoreNumber

signal ChangeNumber(new_num: int, which: Enums.SCORE_BOARD)
@warning_ignore("unused_signal")
signal NewSize(new_size: Vector2)
signal Continue

@onready var _continue_timer := Timer.new()

var right: bool = true
var max_digits: int = 11

@export var tween_limit := 10
@export var tween_mult := 16
@export var continue_hold_time := 0.6
#@export var continue_unhold_time := 0.2

var _scene := preload("res://score_ui.tscn")
var _tweening_to := [-1, -1, -1, -1, -1]

@onready var _game: Control = $"../.."
var _sign: Control

@warning_ignore("shadowed_global_identifier")
static func zfill(str: String, n: int, text_color: Color = Color(1, 1, 1)) -> String:
	return ("[color=#%s]" % (text_color*.5).to_html(false)) + "0".repeat(n-len(str)) + \
		   ("[/color][color=#%s]" % text_color.to_html(false)) + str + "[/color]"

func reset_score_board() -> void:
	change_number(0, Enums.SCORE_BOARD.SCORE_GOAL)
	change_number(_game.round_num, Enums.SCORE_BOARD.ROUND_NUM)
	change_number(0, Enums.SCORE_BOARD.PM_LEFT)
	change_number(0, Enums.SCORE_BOARD.SCORE_CURRENT, true)
	change_number(0, Enums.SCORE_BOARD.PTS_ADDED, true)

func setup_score_board(brd: Board) -> void:
	reset_score_board()
	change_number(_game.round_num, Enums.SCORE_BOARD.ROUND_NUM)
	
	if brd is GameBoard:
		change_number(brd.pm_left, Enums.SCORE_BOARD.PM_LEFT)
		change_number(brd.score_goal, Enums.SCORE_BOARD.SCORE_GOAL)
	else:
		change_number(_game.pts, Enums.SCORE_BOARD.PTS_ADDED)
		

func change_number(new_num: int, which: Enums.SCORE_BOARD, snap: bool = false) -> void:
	match which:
		Enums.SCORE_BOARD.ROUND_NUM: 
			_sign.get_node("VBoxContainer/HBoxContainer/RoundNum").text = "ROUND %s" % zfill(str(new_num), 2)
		Enums.SCORE_BOARD.PM_LEFT:
			_sign.get_node("VBoxContainer/HBoxContainer/PMsLeft").text = "%s LEFT" % zfill(str(new_num), 2)
		Enums.SCORE_BOARD.SCORE_GOAL:
			_sign.get_node("VBoxContainer/ScoreGoal").text = zfill(str(new_num), max_digits)
		Enums.SCORE_BOARD.SCORE_CURRENT:
			if snap:
				_sign.get_node("VBoxContainer/ScoreCurrent").text = zfill(str(new_num), max_digits)
				_tweening_to[which] = -1
			else:
				_tweening_to[which] = new_num
		Enums.SCORE_BOARD.PTS_ADDED:
			if snap:
				_sign.get_node("VBoxContainer/PtsAdded").text = zfill(str(new_num), max_digits, Color(1, 1, 0))
				_tweening_to[which] = -1
			else:
				_tweening_to[which] = new_num

func _get_d(w: bool) -> int:
	return _tweening_to[Enums.SCORE_BOARD.SCORE_CURRENT] - int(_sign.get_node("VBoxContainer/ScoreCurrent").text.rstrip("[/color]").split("]")[-1]) if w else \
	_tweening_to[Enums.SCORE_BOARD.PTS_ADDED] - int(_sign.get_node("VBoxContainer/PtsAdded").text.rstrip("[/color]").split("]")[-1])

func _process(delta: float) -> void:
	if not _continue_timer.is_stopped():
		#TODO nisnifsa
		#if _continue_timer.wait_time == continue_hold_time:
			#_sign.get_node("VBoxContainer/ContinueButton").material.set_shader_parameter("progress", (continue_hold_time - _continue_timer.time_left)/continue_hold_time)
			_sign.get_node("VBoxContainer/ContinueButton").material.set_shader_parameter("progress", (continue_hold_time - _continue_timer.time_left)/continue_hold_time)
		#else:
			#print(_continue_timer.time_left/_continue_timer.wait_time)
			#_sign.get_node("VBoxContainer/ContinueButton").material.set_shader_parameter("progress", _continue_timer.time_left/continue_hold_time)
	elif _sign.get_node("VBoxContainer/ContinueButton").material.get_shader_parameter("progress") > 0:
		var c: float = _sign.get_node("VBoxContainer/ContinueButton").material.get_shader_parameter("progress")
		if c <= .01:
			_sign.get_node("VBoxContainer/ContinueButton").material.set_shader_parameter("progress", 0.)
		else:
			_sign.get_node("VBoxContainer/ContinueButton").material.set_shader_parameter("progress", c-(c*delta/.05))
	
	if _tweening_to[Enums.SCORE_BOARD.SCORE_CURRENT] != -1:
		@warning_ignore("integer_division")
		_sign.get_node("VBoxContainer/ScoreCurrent").text = zfill(str(int(_sign.get_node("VBoxContainer/ScoreCurrent").text.rstrip("[/color]").split("]")[-1]) + max(min(tween_limit, _get_d(true)), int(_get_d(true)/tween_mult))), max_digits)
		#TODO add delta
		if int(_sign.get_node("VBoxContainer/ScoreCurrent").text.rstrip("[/color]").split("]")[-1]) == _tweening_to[Enums.SCORE_BOARD.SCORE_CURRENT]:
			_tweening_to[Enums.SCORE_BOARD.SCORE_CURRENT] = -1
	if _tweening_to[Enums.SCORE_BOARD.PTS_ADDED] != -1:
		@warning_ignore("integer_division")
		_sign.get_node("VBoxContainer/PtsAdded").text = zfill(str(int(_sign.get_node("VBoxContainer/PtsAdded").text.rstrip("[/color]").split("]")[-1]) + max(min(tween_limit, _get_d(false)), int(_get_d(false)/tween_mult))), max_digits, Color(1, 1, 0))
		if int(_sign.get_node("VBoxContainer/PtsAdded").text.rstrip("[/color]").split("]")[-1]) == _tweening_to[Enums.SCORE_BOARD.PTS_ADDED]:
			_tweening_to[Enums.SCORE_BOARD.PTS_ADDED] = -1

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo and event.keycode == Key.KEY_CTRL and \
			(_game.state == Enums.GAME_STATE.SHOP or \
			(_game.state == Enums.GAME_STATE.GAME and _game.board.goal_reached)):
		if event.pressed:
			_continue_timer.start(continue_hold_time)
		else:
			#_continue_timer.start(_continue_timer.wait_time * .5)
			_continue_timer.stop()

func _ready() -> void:
	_continue_timer.one_shot = true
	_continue_timer.timeout.connect(func(): 
		if _continue_timer.wait_time == continue_hold_time: 
			Continue.emit()
			print("CONTINUE")
	)
	add_child(_continue_timer)
	
	_game.PtsChanged.connect(func(new: int):
		if _game.state == Enums.GAME_STATE.SHOP:
			change_number(new, Enums.SCORE_BOARD.PTS_ADDED)
	)
	
	_game.ChangedState.connect(func(new: Enums.GAME_STATE):
		if new == Enums.GAME_STATE.GAME:
			_game.board.ScoreChanged.connect(func():
				if _game.board.goal_reached:
					_sign.get_node("VBoxContainer/ContinueButton").material.set_shader_parameter("avail", true)
					_sign.get_node("VBoxContainer/ContinueButton/RichTextLabel").text = _sign.get_node("VBoxContainer/ContinueButton/RichTextLabel").text.rstrip("[/color]").lstrip("[color=#808080]")
				else:
					_sign.get_node("VBoxContainer/ContinueButton").material.set_shader_parameter("avail", false)
					_sign.get_node("VBoxContainer/ContinueButton/RichTextLabel").text = "[color=#808080]" + _sign.get_node("VBoxContainer/ContinueButton/RichTextLabel").text + "[/color]"
			)
			_sign.get_node("VBoxContainer/ContinueButton").material.set_shader_parameter("avail", false)
			_sign.get_node("VBoxContainer/ContinueButton/RichTextLabel").text = "[color=#808080]" + _sign.get_node("VBoxContainer/ContinueButton/RichTextLabel").text + "[/color]"
		elif new == Enums.GAME_STATE.SHOP:
			_sign.get_node("VBoxContainer/ContinueButton").material.set_shader_parameter("avail", true)
			_sign.get_node("VBoxContainer/ContinueButton/RichTextLabel").text = _sign.get_node("VBoxContainer/ContinueButton/RichTextLabel").text.rstrip("[/color]").lstrip("[color=#808080]")
	)
	
	reset_score_board()

func _init(_m: Board = null, r: bool = true, m_d: int = 11) -> void:
	right = r
	max_digits = m_d
	
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sign = _scene.instantiate()
	add_child(_sign)
	#_sign = $"."
	
	ChangeNumber.connect(change_number)
