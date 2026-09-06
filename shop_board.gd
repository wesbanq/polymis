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

#@onready var _avail_pieces := Enums.read_folder_paths(shape_path)

var _bought_restocks := 0
var _bought_removes := 0
var _mod_chance: float = 15#:
	#get: return _game.round_num*1.5 + 10
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
	
	func set_price(new_price: int) -> void:
		price = new_price
		lbl.change_text(str(new_price))
	
	func _init(pm_: Polymino, price_: int, lbl_: GridLabel) -> void:
		price = price_
		lbl = lbl_
		pm = pm_

class SellingButton:
	var button: ShopButton
	var price: int
	
	func set_price(new_price: int) -> void:
		price = new_price
		button.price = price
		button.lable.change_text(str(price))
	
	func _init(img_path: String, brd: ShopBoard, g_p: Vector2i, price_: int, act: bool = true) -> void:
		button = ShopButton.new(img_path, brd, g_p, price_, act)
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
	var shape: PolyminoShape = load(RNG.pick_random_weight(_get_ranges(ShapeGen.every_pm), ShapeGen.every_pm)).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var new_color := RNG.get_random_color()
	
	for blk in shape.shape_string:
		if blk is BlockInfo:
			blk.color = new_color
			if RNG.randi(0, 100) <= _mod_chance:
				var new_mod := load(RNG.pick_random_weight(_mod_ranges, _avail_mod)).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
				blk.modifier = new_mod
				#new_mod.setup(_game)
	return shape

func purchase(idx: Enums.SHOP_EXTRA_BUTTONS, blks: bool = true) -> void:
	if blks:
		if _game.pts >= selling[idx].price:
			_game.pts -= selling[idx].price
			_game.bag.add(selling[idx].pm.string.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
			BoughtPolymino.emit(selling[idx].pm.string)
			selling[idx].pm.destroy()
			selling[idx].lbl.queue_free()
			selling[idx] = null
		else:
			print("player has: %d, cost: %d" % [_game.pts, selling[idx].price])
	else:
		if _game.pts >= extra_buttons[idx].price:
			match idx:
				Enums.SHOP_EXTRA_BUTTONS.ADD_PM:
					if _game.max_pm >= _game.max_max_pm: return
					_game.max_pm += 1
					IncreasedPMCount.emit()
					_reprice()
					if _game.score_board:
						_game.score_board.ChangeNumber.emit(_game.max_pm, Enums.SCORE_BOARD.PM_LEFT)
				Enums.SHOP_EXTRA_BUTTONS.RESTOCK:
					for i in selling.size():
						if selling[i]:
							selling[i].pm.destroy()
							selling[i].lbl.queue_free()
					_bought_restocks += 1
					_stock_shop()
					_reprice()
					Restock.emit()
				Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL:
					if _game.unlocked_abil_a >= _game.max_abil_a_size: return
					_reprice()
					_game.unlocked_abil_a += 1
					BoughtAbility.emit()
				Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM:
					if _game.bag.size() == 1: 
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
			
			_game.pts -= extra_buttons[idx].price
		else:
			print("player has: %d, cost: %d" % [_game.pts, extra_buttons[idx].price])

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
			if _game.abil_board._next_pms:
				for pm in _game.abil_board._next_pms:
					if _game.pts >= extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].price and _check_inside_pm(world_pos, pm):
						_bought_removes += 1
						_game.bag.remove(pm.string)
						_game.pts -= extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].price
						purchase(Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM, false)
						return
			if _game.abil_board._held_pm:
				if _game.pts >= extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].price and _check_inside_pm(world_pos, _game.abil_board._held_pm):
					_game.bag.remove(_game.abil_board._held_pm.string)
					_bought_removes += 1
					_game.held_polyminos.erase(_game.abil_board._held_pm.string)
					_game.pts -= extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].price
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
		
		var price := Tuner.shop.get_pm_price(pm.string, _game.round_num)
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
		

func _check_eligible(_score: int = 0) -> void:
	for button in extra_buttons:
		if button:
			button.button.set_active(button.price < _game.pts)
	if _game.bag.size() == 1:
		extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].button.set_active(false)
	for pm in selling:
		if pm:
			if pm.price > _game.pts:
				pm.lbl.change_color(Enums.UI.UNAVAIL_TEXT)
			else:
				pm.lbl.change_color(Enums.UI.NORMAL_TEXT)

func _reprice() -> void:
	for pm in selling:
		if pm:
			pm.set_price(Tuner.shop.get_pm_price(pm.pm.string, _game.round_num))
	
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM].set_price(Tuner.shop.add_pm_price(_game.round_num, _game.max_pm))
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK].set_price(Tuner.shop.restock_price(_game.round_num, _bought_restocks))
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM].set_price(Tuner.shop.remove_pm_price(_game.round_num, _bought_removes))
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL].set_price(Tuner.shop.abil_unlock_price(_game.round_num, _game.bought_abils_a))
	
	_check_eligible()

func _place_buttons() -> void:
	if extra_buttons.size() > 0:
		for button in extra_buttons:
			if button:
				button.button.destroy()
				button.button.queue_free()
				button = null
		extra_buttons = []
	
	extra_buttons.resize(5)
	
	var add_pm_button := SellingButton.new("res://shop_add_pm_icon.png", self, _pm_pos(0, false), Tuner.shop.add_pm_price(_game.round_num, _game.max_pm), _game.max_pm < _game.max_max_pm)
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM] = add_pm_button
	add_pm_button.button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][1], Color(1,1,1), true)
	add_child(add_pm_button.button)
	
	var restock_button :=  SellingButton.new("res://restock.png", self, _pm_pos(1, false), Tuner.shop.restock_price(_game.round_num, _bought_restocks))
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK] = restock_button
	restock_button.button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][1], Color(1,1,1), true)
	add_child(restock_button.button)
	
	#if _game.unlocked_abil_a < _game.max_abil_a_size-1:
	var abil_unlock_button := SellingButton.new("res://shop_unlock_abil.png", self, _pm_pos(2, false), Tuner.shop.abil_unlock_price(_game.round_num, _game.bought_abils_a))
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL] = abil_unlock_button
	abil_unlock_button.button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL][1], Color(1,1,1), true)
	add_child(abil_unlock_button.button)
	
	var pm_remove_button := SellingButton.new("res://shop_remove_pm_icon.png", self, _pm_pos(3, false), Tuner.shop.remove_pm_price(_game.round_num, _bought_removes))
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM] = pm_remove_button
	pm_remove_button.button.hover(hover_args[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM][0], hover_args[Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM][1], Color(1,1,1), true)
	add_child(pm_remove_button.button)

func _ready() -> void:
	_stock_shop()
	_place_buttons()
	
	_game.score_board.Continue.connect(BoardClear.emit)
	_game.score_board.setup_score_board(self)
	_game.PausedGame.connect(_tgl_visibility)
	_game.PtsChanged.connect(_check_eligible)
	
	update_block_list()
	update_position()

func _init(s_x: int = _selling_amount*4 + (_selling_amount+1)*_grid_spacing, s_y: int = 24, scle: float = 1.0) -> void:
	##old: s_y: int = _grid_spacing+4+4+4+_grid_spacing
	height = s_y
	width = s_x
	scale = Vector2(scle, scle)
