extends Control
class_name GameMain

signal PolyminoPlaced()
signal NewBoard(Board)
signal ChangedState(int)
signal PtsChanged(int)
signal GameOver
signal HeldPolymino
signal TriggeredAbility(int)
signal BoardChangedAttr(String, Variant)
signal PausedGame(bool)

var max_pm := 20:
	set(v): max_pm = clampi(v, 1, max_max_pm)

const max_max_pm := 99
const max_abil_a_size := 3
const max_abil_p_size := 3

var abils_p: Array[AbilityPassive]
var abils_a: Array[AbilityActive]

var unlocked_abil_a := 0
var unlocked_abil_p := 0

var bought_abils_a := 0
var bought_abils_p := 0

var hold_size: int = 1
var next_size: int = 3

var held_polyminos: Array[PolyminoShape] = []

@onready var default_grid_size_px := int(get_viewport_rect().size.length() * 0.017):
	set(v): default_grid_size_px = v; set_grid_scale(v)
var bag: Bag
var pts: int:
	set(v): pts = max(0, v); PtsChanged.emit(v)

var score_board: ScoreNumber
var abil_board: AbilityControl

var board: GameBoard
var shop: ShopBoard

var round_num := 1
var paused: bool = false:
	set(v): paused = v; PausedGame.emit(v)

var state: Enums.GAME_STATE = Enums.GAME_STATE.SHOP:
	set(v): state = v; ChangedState.emit(state)

@onready var _game_board_container := $HBoxContainer/VBoxContainer/PanelContainer/CenterContainer
@onready var _main_container := $HBoxContainer

#cheats
@export var show_block_position := false
@export var show_bag := false
@export var inf_sp := false
@export var inf_pm := false

func give_mod(x: int, y: int, mod: Modifier) -> void:
	if board and board.block_list[x][y] is Block:
		board.block_list[x][y].modifier = mod
	else:
		push_error("couldnt find block at position (x:%d, y:%d)" % [x, y])

func tgl_ghost() -> void:
	pass

func spwn_pm(s: String, rc: Enums.ROTATION_CENTER = Enums.ROTATION_CENTER.FOUR) -> void:
	if board:
		board.spawn_polymino(PolyminoShape.from_string(s, rc))

func blkt() -> void:
	if board:
		var b1 := spwn_blk(0, 0)
		var b2 := spwn_blk(board.width-1, 0)
		var b3 := spwn_blk(0, board.height-1)
		var b4 := spwn_blk(board.width-1, board.height-1)
		
		if b1: LimboConsole.info("b: (%d, %d); p: (%d, %d); g: (%d, %d)" % [b1.board_position.x, b1.board_position.y, b1.position.x, b1.position.y, b1.global_position.x, b1.global_position.y])
		if b2: LimboConsole.info("b: (%d, %d); p: (%d, %d); g: (%d, %d)" % [b2.board_position.x, b2.board_position.y, b2.position.x, b2.position.y, b2.global_position.x, b2.global_position.y])
		if b3: LimboConsole.info("b: (%d, %d); p: (%d, %d); g: (%d, %d)" % [b3.board_position.x, b3.board_position.y, b3.position.x, b3.position.y, b3.global_position.x, b3.global_position.y])
		if b4: LimboConsole.info("b: (%d, %d); p: (%d, %d); g: (%d, %d)" % [b4.board_position.x, b4.board_position.y, b4.position.x, b4.position.y, b4.global_position.x, b4.global_position.y])

func spwn_blk(x: int, y: int) -> Block:
	if board and not board.check_bounds(Vector2i(x, y)):
		var new_blk = Block.new(BlockInfo.new(), Vector2i(x, y), board, null)
		board.add_child(new_blk)
		board.update_block_list()
		return new_blk
	return

func set_mod(x: int, y: int, mod: String) -> void:
	if board:
		if board.block_list[x][y]:
			var new_mod := PolyminoShape.get_mod_name(mod)
			if new_mod:
				board.block_list[x][y].modifier = new_mod
			else:
				LimboConsole.info("Couldn't find modifier %s" % mod)
		else:
			LimboConsole.info("No block found at position (%d, %d)." % [x, y])

func make_line() -> void:
	if not board: return
	for i in board.width:
		if board.block_list[i][0] is not Block:
			var b = Block.new(BlockInfo.new(), Vector2i(i, 0), board, null)
			board.add_child(b)
	board.update_block_list()
	board.score_current += board.get_score()

#func _new_side_ctrls_size() -> void:
	#if abil_board and score_board:
		#print("sdcvsad")
		#var abil_size := abil_board.get_ctrl_size().x
		#var score_size := score_board.get_ctrl_size().x
		#
		#if abil_size > score_size:
			#score_board.set_ctrl_size(Vector2(abil_size, 0))
		#else:
			#abil_board.set_ctrl_size(Vector2(score_size, 0))

func set_abil_active(idx: int, abil_name: String) -> void:
	if idx > max_abil_a_size or idx < 0: 
		LimboConsole.info("Invalid index.")
		return
	
	var new_abil = AbilityActive.get_abil_name(abil_name)
	
	if new_abil:
		new_abil = new_abil.new(self)
		abils_a[idx] = new_abil
		abil_board.set_abil_at(idx, new_abil)
		LimboConsole.info("Added ability \"%s\" to slot #%d." % [abil_name, idx+1])
	else:
		LimboConsole.info("Couldn't find ability named: \"%s\"" % abil_name)

func _set_round(new_round: int) -> void:
	round_num = new_round
	score_board.ChangeNumber.emit(new_round, Enums.SCORE_BOARD.ROUND_NUM)
	if shop:
		shop._reprice()
	if board:
		board.round_num = round_num

func _skip_board() -> void: 
	if board: 
		board.board_finish(Enums.BOARD_FINISH.WIN_CONTINUE)
		LimboConsole.info("Skipped board.")

func set_sp(add: int) -> void:
	if board:
		board.special_points += add

func set_grid_scale(new_scale: int) -> void:
	if board: 
		board.grid_size_px = new_scale
	elif shop:
		shop.grid_size_px = new_scale

func register_commands() -> void:
	LimboConsole.register_command(func() -> void: LimboConsole.info("Block positions are now %s." % ("HIDDEN" if show_block_position else "SHOWN")); show_block_position = not show_block_position, "blkpos", "Toggles showing block positions.")
	LimboConsole.register_command(func(v: int) -> void: pts += v; LimboConsole.info("Set pts to %d." % pts), "pts", "Adds <arg0> to pts.")
	LimboConsole.register_command(_skip_board, "skip", "Skips to the next shop board.")
	LimboConsole.register_command(spwn_pm, "spm", "Spawns a polymino described by <s> with <rc> rotation center.")
	LimboConsole.register_command(set_grid_scale, "scale", "Changes the scale of the UI to <arg0>.")
	LimboConsole.register_command(spwn_blk, "blk", "Spawns default block at position (<x>, <y>).")
	LimboConsole.register_command(blkt, "blkt")
	LimboConsole.register_command(set_mod, "smod", "Set the modifier of block at position (<x>, <y>) to <mod>.")
	LimboConsole.register_command(set_abil_active, "abil", "Sets ablity in slot <idx> to <abil_name>.")
	LimboConsole.register_command(func() -> void: LimboConsole.info("Active abilities: %v+\nPassive abilities: %v+" % [abils_a, abils_p]), "abils", "Prints the names of all equipped abilities.")
	LimboConsole.register_command(func() -> void: inf_sp = not inf_sp, "infsp", "Toggles infinite SP.")
	LimboConsole.register_command(set_sp, "asp", "Adds <add> to the current SP.")
	LimboConsole.register_command(func() -> void: if board: LimboConsole.info("Current SP: %d" % board.special_points), "sp", "Prints the current amount of SP.")
	LimboConsole.register_command(func(v: int) -> void: if board: board.special_points = v; LimboConsole.info("Set the SP counter to %d." % v), "ssp", "Sets the SP counter to <arg0>.")
	LimboConsole.register_command(func(v: String) -> void: RNG.set_seed(v), "seed", "Sets the game's seed to <arg0>.")
	LimboConsole.register_command(func() -> void: inf_pm = not inf_pm, "infpm", "Gives infinite polymnos.")
	LimboConsole.register_command(func(n: int) -> void: if board and board is GameBoard: board.pm_left += n, "apm", "Adds <arg0> to the current polymino left count.")
	LimboConsole.register_command(func(n: int) -> void: if board and board is GameBoard: board.score_current += n, "score", "Adds <arg0> to the score count.")
	LimboConsole.register_command(func(n: int) -> void: unlocked_abil_a = n, "unlock", "Unlocks ability")
	LimboConsole.register_command(_set_round, "round", "Sets the round to <arg0>.")

@warning_ignore("shadowed_variable_base_class")
func _idk_what_to_call_this_function(name: String, val: Variant) -> void:
	match name:
		"grid_size_px":
			if val is int:
				_main_container.add_theme_constant_override("separation", int(val*.875))
			else:
				push_error("non int val given: %v+" % val)

func trigger_ability(slot: int) -> void:
	if board and slot <= unlocked_abil_a and abils_a.size() > slot and abils_a[slot] and (board.special_points >= abils_a[slot].sp_cost or inf_sp):
		if abils_a[slot].trigger():
			if not inf_sp:
				board.special_points -= abils_a[slot].sp_cost
			TriggeredAbility.emit(slot)
	else:
		print("Not enough SP to trigger ability #%d" % slot)

func _game_loop() -> Enums.BOARD_FINISH:
	var reason: Enums.BOARD_FINISH
	while true:
		board = GameBoard.new(round_num)
		@warning_ignore("shadowed_variable_base_class")
		board.ChangedAttr.connect(func(name: String, val: Variant) -> void: BoardChangedAttr.emit(name, val))
		board.ChangedAttr.connect(_idk_what_to_call_this_function)
		_game_board_container.add_child(board)
		
		#REMOVE L8R VVV dbg
		#board.special_points = 99999
		#board.score_goal = 1
		#board.pm_left = 4
		
		board.spawn_next_pm(bag)
		board.HeldPolymino.connect(HeldPolymino.emit)
		board.PolyminoPlaced.connect(func() -> void:
			board.spawn_next_pm(bag)
			PolyminoPlaced.emit()
		)
		
		state = Enums.GAME_STATE.GAME
		NewBoard.emit(board)
		reason = await board.BoardCleared
		
		#check for loss
		if Enums.is_fail_reason(reason):
			score_board.queue_free()
			abil_board.queue_free()
			board.queue_free()
			GameOver.emit()
			break
		else:
			pts += Tuner.game.round_reward(board.score_current, board.score_goal, round_num)
		
		board.queue_free()
		#GAMEPLAY END
		
		#SHOP
		shop = ShopBoard.new()
		_game_board_container.add_child(shop)
		state = Enums.GAME_STATE.SHOP
		NewBoard.emit(shop)
		@warning_ignore("shadowed_variable_base_class")
		shop.ChangedAttr.connect(func(name: String, val: Variant) -> void: BoardChangedAttr.emit(name, val))
		await shop.BoardClear
		shop.queue_free()
		#SHOP END
		
		round_num += 1
	return reason

func _prep_loop() -> void:
	bag = Bag.load_bag_resource(Enums.BAG_PATHS[0], self)
	bag.reshuffle(true)
	
	abil_board = AbilityControl.new()
	score_board = ScoreNumber.new()
	
	$HBoxContainer.add_child(score_board)
	$HBoxContainer.add_child(abil_board)
	$HBoxContainer.move_child(abil_board, 0)
	
	pts = 0
	abil_board.set_abils_from_arr(abils_a, abils_p)
	RNG.set_seed(RNG.generate_seed())
	
	#to trigger auto scaling (mb fix idk it works so who gives a shit)
	get_viewport().size_changed.emit()

func _input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		if event.is_action("pause_menu"):
			if board or shop: 
				paused = not paused
				Engine.time_scale = 0 if paused else 1
				#Bg.tgl_pause()
		
		if event.is_action("toggle_fullscreen"):
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
		if event.is_action("skip"):
			_skip_board()

func _ready() -> void:
	abils_a.resize(max_abil_a_size)
	abils_a.fill(Enums.ABILITIES_ACTIVE["noabil"].new(self))
	abils_p.resize(max_abil_p_size)
	
	#var test_seed := "0001209C"
	#RNG.set_seed(test_seed)
	register_commands()
	
	Bg.activate()
	get_viewport().size_changed.connect(func() -> void:
		default_grid_size_px = int(get_viewport_rect().size.length() * .016)
		if score_board and abil_board:
			await get_tree().process_frame
			score_board.set_ctrl_size(Vector2(abil_board.get_ctrl_size().x, 0))
	)
	
	while true:
		await _prep_loop()
		var reason := await _game_loop()
		print("IT'S OVER. %s" % Enums.BOARD_FINISH.keys()[reason])
