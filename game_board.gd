extends Board
class_name GameBoard

signal PolyminoPlaced(pm: Polymino)
signal Scored(amount: int)
signal LineFinished(amount: int)
signal BoardCleared(reason: int)
signal ScoreChanged
signal HeldPolymino

var _controlled_polymino: Polymino
var _down_timer: Timer
var _hold_cooldown: bool = false

var paused_input := 0:
	set(v):
		paused_input = v
		if _down_timer: _down_timer.paused = paused_input > 0

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
	get: 
		@warning_ignore("integer_division")
		return (score_current - score_goal) / 1000
var goal_reached: bool:
	get: 
		return score_current >= score_goal

var round_num: int

var special_points := 0:
	set(v): special_points = clampi(v, 0, 100); ChangedAttr.emit("special_points", v)

@onready var next_board: Board = Board.new(4*game.next_size+max(game.next_size-1, 0), 4)
@onready var hold_board: Board = Board.new(4*game.hold_size+max(game.hold_size-1, 0), 4)

func spawn_polymino(ps: PolyminoShape, origin: Vector2i = Vector2i(int(width/2.0 - 2)+1, height-4)) -> void:
	if _controlled_polymino != null:
		push_error("spwaned pm while thers a pm active")
		_controlled_polymino.destroy()
		_controlled_polymino = null
	
	_controlled_polymino = _add_polymino(ps, origin)
	_controlled_polymino.PolyminoPlaced.connect(_polymino_placed)
	
	#check gameover
	if _controlled_polymino.check_collision(Vector2i(0, -1)):
		board_finish(Enums.BOARD_FINISH.LOSE_NO_SPACE)
		return

func board_finish(reason: Enums.BOARD_FINISH) -> void:
	if _controlled_polymino != null:
		_controlled_polymino.destroy()
		_controlled_polymino = null
	BoardCleared.emit(reason)

const SHIFT_LINE_DELAY := 0.3
func move_rows_down(from_y: int, amount: int = 1) -> void:
	for y in range(from_y, height-1):
		for x in width:
			if block_list[x][y] is Block and not block_list[x][y-amount] is Block:
				block_list[x][y].board_position.y -= amount
				block_list[x][y-amount] = block_list[x][y]
				block_list[x][y] = null
	update_block_list()

func score_line(line: int, completed: int, play_effect: bool) -> int:
	var scored = 0
	
	for x in width:
		var score: int = block_list[x][line].score()
		#gradually speed up the flash time
		#block_list[x][y].flash_with_number(score)
		if play_effect:
			await block_list[x][line].effect(score, Tuner.effects.flash_time(completed, x, width), Tuner.effects.pitch(completed, x, width))
		scored += score
	update_block_list()
	
	return scored

func trigger(line: int, pre: bool) -> void:
	for x in width:
		if pre: block_list[x][line].pre_trigger()
		else: block_list[x][line].post_trigger()

func _destroy_line(line: int) -> void:
	paused_input += 1
	#for x in line: block_list[x][line].flash_with_number()
	for x in width: block_list[x][line].destroy()
	update_block_list()
	await get_tree().create_timer(SHIFT_LINE_DELAY).timeout
	move_rows_down(line+1)
	paused_input -= 1

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
	#dont allow holding last piece unless switching betweenkojsgn
	if not _hold_cooldown and (pm_left > 0 or (pm_left == 0 and game.held_polyminos.size() > 0)): 
		if game.held_polyminos.size() >= game.hold_size:
			var new_polymino = game.held_polyminos.pop_front()
			if _controlled_polymino:
				game.held_polyminos.append(_controlled_polymino.string)
				_controlled_polymino.destroy()
				_controlled_polymino = null
			spawn_polymino(new_polymino)
		else:
			game.held_polyminos.append(_controlled_polymino.string)
			_controlled_polymino.destroy()
			_controlled_polymino = null
			spawn_next_pm(game.bag)
		_hold_cooldown = true
		HeldPolymino.emit()

func trigger_ability(idx: int) -> void:
	game.trigger_ability(idx)

func setup_timer() -> void:
	#print(falling_speed)
	_down_timer.wait_time = Tuner.game.falling_speed(round_num)
	_down_timer.paused = paused_input
	_down_timer.start()

func _remove_controlled_pm() -> void:
	if _controlled_polymino:
		for v in _controlled_polymino.get_children():
			v.reparent(self)
		update_block_list()
		
		if _controlled_polymino.ghost: 
			_controlled_polymino.ghost.queue_free()
		_controlled_polymino.queue_free()
		_controlled_polymino = null
		_hold_cooldown = false

func _check_for_line_completions() -> void:
	var lines := get_scoring_lines()
	if lines.size() > 0:
		paused_input += 1
		var sp_to_add := Tuner.game.sp_from_lines(lines, self)
		print("Scored: %d" % lines.size())
		
		var i := 0
		for line in lines:
			var eff := false
			for x in width: 
				if block_list[x][line].modifier:
					eff = true
					break
			
			trigger(line, true)
			score_to_add += await score_line(line, i, eff)
			trigger(line, false)
			ScorePopup.create(
				self, 
				score_to_add, 
				0.3, 
				1.25, 
				grid_size_px * (line-height+3),
				-grid_size_px * (width-1) / 2.
			)
			SFX.play_line()
			for x in width: 
				block_list[x][line].flash_with_number(0, Tuner.effects.flash_time(i, x, width))
			#await block_list[width-1][line].flash_with_number(0, _calc_flash_time(i, width-1))
			_destroy_line(line)
			
			i += 1
		
		score_current += score_to_add
		Scored.emit(score_to_add)
		
		score_to_add = 0
		special_points += sp_to_add
		paused_input -= 1
		#await _check_for_line_completions()

func _toggle_visibility(paused: bool) -> void:
	if _down_timer: _down_timer.paused = paused or paused_input
	
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

func spawn_next_pm(bag: Bag) -> void:
	if pm_left <= 0:
		if game.held_polyminos.size() > 0:
			spawn_polymino(game.held_polyminos.pop_front())
			HeldPolymino.emit()
		#else:
			#push_error("no pm left.")
	else:
		spawn_polymino(bag.get_next())
		pm_left -= 1

func _ready() -> void:
	height += 4 # for spawning polyminos
	update_block_list()
	update_position()
	
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

func _init(r: float, s_x: int = 10, s_y: int = 20, scle: float = 1.0) -> void:
	super(s_x, s_y, scle)
	round_num = r

func _check_loss() -> void:
	if pm_left <= 0 and game.held_polyminos.size() == 0:
		if goal_reached:
			board_finish(Enums.BOARD_FINISH.WIN_PM_LEFT)
		else:
			board_finish(Enums.BOARD_FINISH.LOSE_PM_LEFT)

func _polymino_placed() -> void:
	_remove_controlled_pm()
	await _check_for_line_completions()
	_check_loss()
	
	PolyminoPlaced.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_echo() or \
	event.is_released() or \
	not _controlled_polymino or \
	game.paused or paused_input > 0: 
		return
	
	if event.is_action("snap_down"):
		_controlled_polymino.snap_down()
		_polymino_placed()
	
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
