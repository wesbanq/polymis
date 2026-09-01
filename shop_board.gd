extends Board
class_name ShopBoard

signal BoughtPolymino(ps: PolyminoShape)
signal BoughtAbility
signal Restock
signal BoardClear
signal IncreasedPMCount

@export var _selling_amount := 3
@export var _grid_spacing := 1

const PM_SIZE := 4

@onready var _avail_pieces := Enums.read_folder_paths(shape_path)
@onready var _ranges: Array[float] = _get_ranges(_avail_pieces)

var _mod_chance: float = 15#:
	#get: return game.round_num*1.5 + 10
@onready var _avail_mod := Enums.read_folder_paths(mod_path)
@onready var _mod_ranges: Array[float] = _get_ranges(_avail_mod)

var selling: Array[SellingPM]
var extra_buttons: Array[SellingButton]
var removing: bool = false

const mod_path := "res://modifiers/resources/"
const shape_path := "res://polymino_shapes/"

var hover_args := {
	Enums.SHOP_EXTRA_BUTTONS.ADD_PM: ["Add polymino", "Adds 1 to you max polymino count per round."],
	Enums.SHOP_EXTRA_BUTTONS.RESTOCK: ["Restock", "Restock the shop."],
	Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL: ["Unlock ability", "Unlocks new ability."],
	Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM: ["Remove polymino", "Remove your chosen polymino from your bag."],
}

class SellingPM:
	var price: int
	var lbl: GridLabel
	var pm: Polymino
	
	func _init(pm_: Polymino, price_: int, lbl_: GridLabel) -> void:
		price = price_
		lbl = lbl_
		pm = pm_

class SellingButton:
	var button: ShopButton
	var price: int
	
	func _init(price_: int, button_: ShopButton) -> void:
		button = button_
		price = price_

static func _get_ranges(weight_src: Array[Variant]) -> Array[float]:
	var result: Array[float]
	#create a list of ranges all corresponding to a polymino
	#the length of a ranges is determined by the polyminos weight	
	for v in weight_src:
		var tmp := load(v)
		result.append(tmp.weight + (result[-1] if result.size() > 0 else 0.))
	return result

@warning_ignore("shadowed_variable")
func _get_random_pm() -> PolyminoShape:
	#duplicate deep so as not to change the original polyminoshape resources
	var shape: PolyminoShape = load(RNG.pick_random_weight(_ranges, _avail_pieces)).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var new_color := RNG.get_random_color()
	
	for blk in shape.shape_string:
		if blk is BlockInfo:
			blk.color = new_color
			if RNG.randi(0, 100) <= _mod_chance:
				var new_mod := load(RNG.pick_random_weight(_mod_ranges, _avail_mod)).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
				blk.modifier = new_mod
				#new_mod.setup(game)
	return shape

func purchase(idx: Enums.SHOP_EXTRA_BUTTONS, blks: bool = true) -> void:
	if blks:
		if game.pts >= selling[idx].price:
			game.pts -= selling[idx].price
			game.bag.add(selling[idx].pm.string.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
			BoughtPolymino.emit(selling[idx].pm.string)
			selling[idx].pm.destroy()
			selling[idx].lbl.queue_free()
			selling[idx] = null
		else:
			print("player has: %d, cost: %d" % [game.pts, selling[idx].price])
	else:
		if game.pts >= extra_buttons[idx].price:
			match idx:
				Enums.SHOP_EXTRA_BUTTONS.ADD_PM:
					game.max_pm += 1
					IncreasedPMCount.emit()
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM].button.destroy()
					
					#if game.max_pm < game.max_max_pm:
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM].price = Tuner.shop.add_pm_price(game.round_num, game.max_pm)
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM].button = ShopButton.new(
						"res://shop_add_pm_icon.png", 
						self, 
						_pm_pos(Enums.SHOP_EXTRA_BUTTONS.ADD_PM, false),
						game.max_pm < game.max_max_pm
					)
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM].button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][1], Color(1,1,1), true)
					add_child(extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM].button)
					#sends signal to score board to change pm value
					#TODO crutch pls fix (mb not idk)
					if game.score_board:
						game.score_board.ChangeNumber.emit(game.max_pm, Enums.SCORE_BOARD.PM_LEFT)
				Enums.SHOP_EXTRA_BUTTONS.RESTOCK:
					for i in selling.size():
						if selling[i]:
							selling[i].pm.destroy()
							selling[i].lbl.queue_free()
					_stock_shop()
					Restock.emit()
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK].button.destroy()
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK].price = Tuner.shop.add_pm_price(game.round_num, game.max_pm)
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK].button = ShopButton.new(
						"res://restock.png", 
						self, 
						_pm_pos(Enums.SHOP_EXTRA_BUTTONS.RESTOCK, false)
					)
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK].button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][1], Color(1,1,1), true)
					add_child(extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK].button)
				Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL:
					game.unlocked_abil_a += 1
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL].button.destroy()
					#if game.unlocked_abil_a < game.max_abil_a_size-1:
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL].price = Tuner.shop.add_pm_price(game.round_num, game.max_pm)
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL].button = ShopButton.new(
						"res://shop_unlock_abil.png", 
						self,
						_pm_pos(Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL, false), 
						game.unlocked_abil_a < game.max_abil_a_size-1
					)
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL].button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL][1], Color(1,1,1), true)
					BoughtAbility.emit()
					add_child(extra_buttons[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL].button)
				Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM:
					if game.bag.size() == 1: 
						removing = false
						return
					if removing:
						extra_buttons[idx].button.change_color(Enums.UI.NORMAL_TEXT)
					else:
						extra_buttons[idx].button.change_color(Enums.UI.REMOVING_SHOP_BUTTON)
					removing = not removing
					return
				Enums.SHOP_EXTRA_BUTTONS.UNLOCK_PASSIVE_ABIL:
					pass
				_:
					push_error("unknodwn: ", idx)
			
			game.pts -= extra_buttons[idx].price
		else:
			print("player has: %d, cost: %d" % [game.pts, selling[idx].price])

static func _check_inside_pm(pos: Vector2, pm: Polymino) -> bool:
	for blk in pm.blocks:
		if blk is Block and blk.click_within_block(pos):
			return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and event.pressed and event.button_index == 1:
		var world_pos: Vector2 = (get_viewport().get_screen_transform() * get_viewport().get_canvas_transform()).affine_inverse() * event.position
		for i in _selling_amount:
			var pm = selling[i]
			if pm and _check_inside_pm(world_pos, pm.pm):
				purchase(i)
				return
		
		if removing:
			if game.abil_board._next_pms:
				for pm in game.abil_board._next_pms:
					if game.pts >= extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].price and _check_inside_pm(world_pos, pm):
						game.bag.remove(pm.string)
						game.pts -= extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].price
						purchase(Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM, false)
						return
			if game.abil_board._held_pm:
				if game.pts >= extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].price and _check_inside_pm(world_pos, game.abil_board._held_pm):
					game.bag.remove(game.abil_board._held_pm.string)
					game.held_polyminos.erase(game.abil_board._held_pm.string)
					game.pts -= extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].price
					purchase(Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM, false)
					return
		
		for key in Enums.SHOP_EXTRA_BUTTONS:
			if extra_buttons[Enums.SHOP_EXTRA_BUTTONS[key]] and extra_buttons[Enums.SHOP_EXTRA_BUTTONS[key]].button.click_within_block(world_pos):
				purchase(Enums.SHOP_EXTRA_BUTTONS[key], false)

func _pm_pos(i: int, a: bool = true) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(i*PM_SIZE + (i+1)*_grid_spacing + 1 if a else (2*i-1) + (i+1)*_grid_spacing + 2, 
					height - height/3 if a else height/3)
	#return Vector2i(i*PM_SIZE + (i+1)*_grid_spacing + 1, height/2)

func _stock_shop() -> void:
	selling = []
	for i in range(_selling_amount):
		#TODO wacky behaviour w/ "height/2 - PM_SIZE/2"
		var pm := _add_polymino(
			_get_random_pm(), 
			_pm_pos(i), 
			false,
			true
		)
		
		var price := Tuner.shop.get_pm_price(pm.string, game.round_num)
		var lbl := GridLabel.new(_pm_pos(i) + Vector2i(0, -1), str(price), self)
		add_child(lbl)
		
		selling.append(SellingPM.new(pm, price, lbl))

func _tgl_visibility(paused: bool) -> void:
	for pm in selling:
		if pm:
			for blk in pm.pm.blocks:
				if blk is Block:
					if blk._hoverable: blk._hoverable.temp_hidden = paused
					blk.visible = not paused
			pm.lbl.visible = not paused
	
	for arr in extra_buttons:
		if arr:
			arr.button.set_visibility(not paused)
		

func _check_eligible(_score: int) -> void:
	for button in extra_buttons:
		if button:
			button.button.set_active(button.price < game.pts)
	if game.bag.size() == 1:
		extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].button.set_active(false)
	for pm in selling:
		if pm:
			if pm.price > game.pts:
				pm.lbl.change_color(Enums.UI.UNAVAIL_TEXT)
			else:
				pm.lbl.change_color(Enums.UI.NORMAL_TEXT)

func _place_buttons() -> void:
	if extra_buttons.size() > 0:
		for button in extra_buttons:
			button.button.queue_free()
			button = null
		extra_buttons = []
	
	extra_buttons.resize(5)
	
	var add_pm_button := ShopButton.new("res://shop_add_pm_icon.png", self, _pm_pos(0, false), game.max_pm < game.max_max_pm)
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM] = SellingButton.new(Tuner.shop.add_pm_price(game.round_num, game.max_pm), add_pm_button)
	add_pm_button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][1], Color(1,1,1), true)
	add_child(add_pm_button)
	
	var restock_button := ShopButton.new("res://restock.png", self, _pm_pos(1, false))
	restock_button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][1], Color(1,1,1), true)
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK] = SellingButton.new(Tuner.shop.restock_price(game.round_num, game.max_pm), restock_button)
	add_child(restock_button)
	
	#if game.unlocked_abil_a < game.max_abil_a_size-1:
	var abil_unlock_button := ShopButton.new("res://shop_unlock_abil.png", self, _pm_pos(2, false))
	abil_unlock_button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL][1], Color(1,1,1), true)
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL] = SellingButton.new(Tuner.shop.restock_price(game.round_num, game.max_pm), abil_unlock_button)
	add_child(abil_unlock_button)
	
	var pm_remove_button := ShopButton.new("res://shop_remove_pm_icon.png", self, _pm_pos(3, false))
	pm_remove_button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM][1], Color(1,1,1), true)
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM] = SellingButton.new(Tuner.shop.restock_price(game.round_num, game.max_pm), pm_remove_button)
	add_child(pm_remove_button)

func _ready() -> void:
	_stock_shop()
	
	game.score_board.Continue.connect(BoardClear.emit)
	game.score_board.setup_score_board(self)
	game.PausedGame.connect(_tgl_visibility)
	game.PtsChanged.connect(_check_eligible)
	
	update_block_list()
	update_position()

func _init(s_x: int = _selling_amount*4 + (_selling_amount+1)*_grid_spacing, s_y: int = 24, scle: float = 1.0) -> void:
	##old: s_y: int = _grid_spacing+4+4+4+_grid_spacing
	height = s_y
	width = s_x
	scale = Vector2(scle, scle)
