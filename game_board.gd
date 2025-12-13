extends Board
class_name GameBoard

signal PolyminoPlaced(Polymino)
signal Scored(int)
signal LineFinished(int)
signal SPAdd(int)
signal BoardCleared(int)
signal ScoreChanged
signal HeldPolymino

var _controlled_polymino: Polymino
var _down_timer: Timer

var _held_polyminos: Array[PolyminoShape]
var _hold_cooldown: bool = false

var score_to_add: int
var score_current := 0:
	set(v): 
		score_current = v
		ScoreChanged.emit()
		game.score_board.ChangeNumber.emit(score_current, Enums.SCORE_BOARD.SCORE_CURRENT)
		game.score_board.ChangeNumber.emit(max(pts_added, 0), Enums.SCORE_BOARD.PTS_ADDED)

@onready var pm_left: int = game.max_pm: #TODO fomrula
	set(v): pm_left = v; game.score_board.ChangeNumber.emit(pm_left, Enums.SCORE_BOARD.PM_LEFT)
@onready var score_goal: int = game.round_num * (width*100):
	set(v): score_goal = v; game.score_board.ChangeNumber.emit(score_goal, Enums.SCORE_BOARD.SCORE_GOAL)

var pts_added: int:
	get: return (score_current - score_goal)/1000
var goal_reached: bool:
	get: return score_current >= score_goal

var difficulty: float = 1.0
var falling_speed: float:
	get: return 1.59658/(1+exp(1)**(.556572*difficulty - 3.2994))

var special_points := 0:
	set(v): special_points = clampi(v, 0, 100); ChangedAttr.emit("special_points", v)

@onready var next_board: Board = Board.new(4*game.next_size+max(game.next_size-1, 0), 4)
@onready var hold_board: Board = Board.new(4*game.hold_size+max(game.hold_size-1, 0), 4)

func spawn_polymino(ps: PolyminoShape, origin: Vector2i = Vector2i(int(width/2.0 - 2)+1, height-4)) -> void:
	if pm_left <= 0:
		pm_left += 1
		if goal_reached:
			board_finish(Enums.BOARD_FINISH.WIN_PM_LEFT)
		else:
			board_finish(Enums.BOARD_FINISH.LOSE_PM_LEFT)
		return
	
	if _controlled_polymino != null:
		push_error("spwaned pm while thers a pm active")
		_controlled_polymino.destroy()
		_controlled_polymino = null
	
	_controlled_polymino = _add_polymino(ps, origin)
	
	#check gameover
	if _controlled_polymino.check_collision(Vector2i(0, -1)):
		board_finish(Enums.BOARD_FINISH.LOSE_NO_SPACE)
		return

func board_finish(reason: Enums.BOARD_FINISH) -> void:
	BoardCleared.emit(reason)
	if _controlled_polymino != null:
		_controlled_polymino.destroy()
		_controlled_polymino = null
	
	if not Enums.is_fail_reason(reason):
		game.pts += pts_added

func move_rows_down(from_y: int, amount: int = 1) -> void:
	for y in range(from_y, height-1):
		for x in width:
			#print("%s, x: %s, y: %s" % [block_list[x][y], x, y])
			if block_list[x][y] is Block and not block_list[x][y-amount] is Block:
				block_list[x][y].board_position.y -= amount
				block_list[x][y-amount] = block_list[x][y]
				block_list[x][y] = null
	update_block_list()

func score_lines(lines: Array[int]) -> int:
	var scored = 0
	for y in lines:
		for x in width:
			scored += block_list[x][y].score()
			#block_list[x][y] = null
		update_block_list()
		#move_rows_down(y+1)
	return scored

func trigger(lines: Array[int], pre: bool) -> void:
	for y in lines:
		for x in width:
			if pre: block_list[x][y].pre_trigger()
			else: block_list[x][y].post_trigger()

func destroy_lines(lines: Array[int]) -> void:
	for y in lines:
		for x in width:
			block_list[x][y].destroy()
		update_block_list()
		move_rows_down(y+1)

func get_scoring_lines() -> Array[int]:
	#var score := 0
	var lines: Array[int] = []
	for y in range(height-1, -1, -1):
		var complete := true
		for x in width:
			if not block_list[x][y] is Block:
				complete = false
				break
		if complete:
			LineFinished.emit(y)
			lines.append(y)
	#for line in lines: score += score_row(line)
	
	return lines

func hold_polymino() -> void:
	if not _hold_cooldown: 
		if _held_polyminos.size() >= game.hold_size:
			var new_polymino = _held_polyminos.pop_front()
			_held_polyminos.append(_controlled_polymino.string)
			_controlled_polymino.destroy()
			_controlled_polymino = null
			spawn_polymino(new_polymino)
		else:
			_held_polyminos.append(_controlled_polymino.string)
			_controlled_polymino.destroy()
			_controlled_polymino = null
			spawn_polymino(game.bag.next)
		_hold_cooldown = true
		HeldPolymino.emit()
		print(_held_polyminos)

func trigger_ability(idx: int) -> void:
	game.trigger_ability(idx)

func setup_timer() -> void:
	#print(falling_speed)
	_down_timer.wait_time = falling_speed
	_down_timer.start()

func _check_for_line_completions(pm: Polymino = null) -> void:
	if pm: 
		for v in pm.get_children():
			v.reparent(self)
		
		update_block_list()
		if pm.ghost: pm.ghost.queue_free()
		pm.queue_free()
		_controlled_polymino = null
		_hold_cooldown = false
	
		#game.PolyminoPlaced.emit(pm)
	#score_to_add = get_score()
	
	var lines := get_scoring_lines()
	if lines.size() > 0:
		var sp_to_add := Enums.sp_from_lines(lines, self)
		special_points += sp_to_add
		print("Scored: %d" % lines.size())
		trigger(lines, true)
		score_to_add = score_lines(lines)
		trigger(lines, false)
		
		score_current += score_to_add
		Scored.emit(score_to_add)
		
		destroy_lines(lines)
		score_to_add = 0
		#print(pm)
		_check_for_line_completions()
	if pm: game.PolyminoPlaced.emit(pm)

func _toggle_visibility(paused: bool) -> void:
	if _down_timer: _down_timer.paused = paused
	if _controlled_polymino:
		for blk in _controlled_polymino.blocks:
			if blk is Block:
				if blk._hoverable: blk._hoverable.temp_hidden = paused
				blk.visible = not paused
		if _controlled_polymino.ghost:
			for blk in _controlled_polymino.ghost.blocks:
				if blk is Block:
					blk.visible = not paused
	for x in block_list:
		for blk in x:
			if blk is Block:
				blk.visible = not paused

func destroy_block_at(pos: Vector2i) -> void:
	if block_list[pos.x][pos.y]:
		block_list[pos.x][pos.y].destroy()
		block_list[pos.x][pos.y] = null
		if _controlled_polymino.ghost:
			_controlled_polymino.ghost.UpdateGhost.emit()

func _ready() -> void:
	#scale = Vector2(.5, .5) # remove l8r
	height += 4 # for spawning polyminos
	update_block_list()
	update_position()
	
	PolyminoPlaced.connect(_check_for_line_completions)
	
	_down_timer = Timer.new()
	_down_timer.timeout.connect(func():
		if _controlled_polymino != null:
			_controlled_polymino.DownTimer.emit()
	)
	
	game.score_board.Continue.connect(func():
		if pts_added >= 0:
			board_finish(Enums.BOARD_FINISH.WIN_CONTINUE)
	)
	game.score_board.setup_score_board(self)
	game.PausedGame.connect(_toggle_visibility)
	
	_down_timer.autostart = true
	add_child(_down_timer)
	setup_timer()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_echo() or event.is_released() or not _controlled_polymino or game.paused: return
	
	if event.is_action("snap_down"):
		_controlled_polymino.snap_down()
		#var send := _controlled_polymino.duplicate()
		#_check_for_line_completions(_controlled_polymino)
		#PolyminoPlaced.emit(send)
		PolyminoPlaced.emit(_controlled_polymino)
	
	if event.is_action("hold"):
		hold_polymino()
	
	if event.is_action("move_down"):
		_controlled_polymino.move(Vector2i(0, -1))
		_down_timer.start()
	
	if event.is_action("move_left"):
		_controlled_polymino.move(Vector2i(-1, 0))
	
	if event.is_action("move_right"):
		_controlled_polymino.move(Vector2i(1, 0))
	
	if event.is_action("rotate_cw"):
		_controlled_polymino.turn(true)
	
	if event.is_action("rotate_ccw"):
		_controlled_polymino.turn(false)
	
	if event.is_action("abil_1"):
		trigger_ability(0)
	
	if event.is_action("abil_2"):
		trigger_ability(1)
	
	if event.is_action("abil_3"):
		trigger_ability(2)
