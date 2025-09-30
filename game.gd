extends Control

@warning_ignore("unused_signal")
signal PolyminoPlaced(pm: Polymino)
@warning_ignore("unused_signal")
signal NewBoard(new: Board)
signal ChangedState(new: Enums.GAME_STATE)
signal PtsChanged(new: int)
signal GameOver

var abils_p: Array
var abils_a: Array

var hold_size: int = 1
var next_size: int = 3

@onready var bag: Bag = preload("res://preset_bags/normal.tres")
var pts := 9999:
	set(v): pts = v; PtsChanged.emit(v)

@onready var score_board := ScoreNumber.new()
#@onready var board: GameBoard = GameBoard.new()
#@onready var shop: ShopBoard = ShopBoard.new()
var board: GameBoard
var shop: ShopBoard

var round_num := 1
var state: Enums.GAME_STATE = Enums.GAME_STATE.SHOP:
	set(v): state = v; ChangedState.emit(state)

@onready var container := $HBoxContainer/VBoxContainer

@export var show_block_position := false
@export var show_bag := false

func give_mod(x: int, y: int, mod: Modifier) -> void:
	if board.block_list[x][y] is Block:
		board.block_list[x][y].modifier = mod
	else:
		push_error("couldnt find block at position (x:%d, y:%d)" % [x, y])

func tgl_ghost() -> void:
	pass

func spwn_pm(s: String, rc: Enums.ROTATION_CENTER = Enums.ROTATION_CENTER.FOUR) -> void:
	if board:
		board.spawn_polymino(PolyminoShape.from_string(s, rc), )
		board.pm_left += 1
	

func make_line() -> void:
	for i in board.width:
		if board.block_list[i][0] is not Block:
			var b = Block.new(BlockInfo.new(), Vector2i(i, 0), board)
			board.add_child(b)
	board.update_block_list()
	board.score_current += board.get_score()

static func is_fail_reason(reason: Enums.BOARD_FINISH) -> bool: return reason >= 2

func _ready() -> void:
	RNG.initialize(73884)
	$HBoxContainer.add_child(score_board)
	
	LimboConsole.register_command(func() -> void: LimboConsole.info("Block positions are now %s." % ("HIDDEN" if show_block_position else "SHOWN")); show_block_position = not show_block_position, "blkpos", "Toggles showing block positions.")
	LimboConsole.register_command(func(v: int) -> void: pts += v; LimboConsole.info("Set pts to %d." % pts), "pts", "Adds arg0 to pts.")
	LimboConsole.register_command(func() -> void: if board: board.board_finish(Enums.BOARD_FINISH.WIN_CONTINUE); LimboConsole.info("Skipped board."), "skip", "Skips to the next shop board.")
	LimboConsole.register_command(spwn_pm, "spm", "Spawns a polymino described by arg0.")
	
	while true:
		board = GameBoard.new()
		container.add_child(board)
		board.spawn_polymino(bag.next)
		board.PolyminoPlaced.connect(func(_v):
			board.spawn_polymino(bag.next)
		)
		board.score_goal = 10
		board.pm_left = 50
		
		state = Enums.GAME_STATE.GAME
		var reason = await board.BoardCleared
		board.queue_free()
		if is_fail_reason(reason):
			score_board.queue_free()
			GameOver.emit()
			break
		
		shop = ShopBoard.new()
		container.add_child(shop)
		state = Enums.GAME_STATE.SHOP
		await shop.BoardClear
		shop.queue_free()
		
		round_num += 1
