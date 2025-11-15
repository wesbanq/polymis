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

@onready var _avail_pieces := Enums.read_folder(shape_path)
@onready var _ranges: Array[float] = _get_ranges(_avail_pieces)

var _mod_chance: float = 15#:
	#get: return game.round_num*1.5 + 10
@onready var _avail_mod := Enums.read_folder(mod_path)
@onready var _mod_ranges: Array[float] = _get_ranges(_avail_mod)

var selling: Array
var extra_buttons: Array

const mod_path := "res://modifiers/resources/"
const shape_path := "res://polymino_shapes/"

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
				new_mod.setup(game)
	return shape

func _get_pm_price(ps: PolyminoShape) -> int:
	var n := 0
	var m := 0
	var p := 0
	
	for blk in ps.shape_string:
		if blk is BlockInfo:
			n += 1
			if blk.modifier != null: 
				m += 1
				p += blk.modifier.mod_price
	
	@warning_ignore("narrowing_conversion")
	return clampi(85*game.round_num + game.round_num**(n*.7) + ((p*m)/float(n))**(game.round_num*.15), 0, 999999)

func purchase(idx: int, blks: bool = true) -> void:
	if blks:
		if game.pts >= selling[idx][1]:
			game.pts -= selling[idx][1]
			game.bag.add_to_bag(selling[idx][0].string.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
			BoughtPolymino.emit(selling[idx][0].string)
			selling[idx][0].destroy()
			selling[idx][2].queue_free()
			selling[idx] = null
		else:
			print("player has: %d, cost: %d" % [game.pts, selling[idx][1]])
	else:
		if game.pts >= extra_buttons[idx][0]:
			game.pts -= extra_buttons[idx][0]
			match idx:
				Enums.SHOP_EXTRA_BUTTONS.ADD_PM:
					game.max_pm += 1
					IncreasedPMCount.emit()
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][1].destroy()
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][0] = Enums.shop_add_pm_price(game.round_num, game.max_pm)
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][1] = ShopButton.new("res://shop_add_pm_icon.png", self, _pm_pos(0, false))
					add_child(extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM][1])
					#sends signal to score board to change pm value
					#TODO crutch pls fix
					if game.score_board:
						game.score_board.ChangeNumber.emit(game.max_pm, Enums.SCORE_BOARD.PM_LEFT)
				Enums.SHOP_EXTRA_BUTTONS.RESTOCK:
					for i in selling.size():
						if selling[i]:
							selling[i][0].destroy()
							selling[i][2].queue_free()
					_stock_shop()
					Restock.emit()
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][0] = Enums.shop_add_pm_price(game.round_num, game.max_pm)
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][1] = ShopButton.new("res://restock.png", self, _pm_pos(1, false))
					add_child(extra_buttons[1][1])
				Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL:
					game.unlocked_abil_a += 1
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][1].destroy()
					#if game.unlocked_abil_a < game.max_abil_a_size-1:
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][0] = Enums.shop_add_pm_price(game.round_num, game.max_pm)
					extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][1] = ShopButton.new(
						"res://shop_unlock_abil.png", 
						self, 
						_pm_pos(2, false), 
						game.unlocked_abil_a < game.max_abil_a_size-1
					)
					BoughtAbility.emit()
					add_child(extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK][1])
				Enums.SHOP_EXTRA_BUTTONS.REMOVE_PM:
					pass
				Enums.SHOP_EXTRA_BUTTONS.UNLOCK_PASSIVE_ABIL:
					pass
				_:
					push_error("unknodwn: %d" % idx)
		else:
			print("player has: %d, cost: %d" % [game.pts, selling[idx][1]])

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and event.pressed and event.button_index == 1:
		var world_pos = (get_viewport().get_screen_transform() * get_viewport().get_canvas_transform()).affine_inverse() * event.position
		for i in _selling_amount:
			var pm = selling[i]
			if pm is Array and pm[0] is Polymino:
				for blk in pm[0].blocks:
					if blk is Block and blk.click_within_block(world_pos):
						purchase(i)
						return
		
		for i in extra_buttons.size():
			if extra_buttons[i] and extra_buttons[i][1].click_within_block(world_pos):
				purchase(i, false)

func _pm_pos(i: int, a: bool = true) -> Vector2i:
	return Vector2i(i*PM_SIZE + (i+1)*_grid_spacing + 1, height - height/3 if a else height/3)
	#return Vector2i(i*PM_SIZE + (i+1)*_grid_spacing + 1, height/2)

func _stock_shop() -> void:
	selling = []
	for i in range(_selling_amount):
		#TODO wacky behaviour w/ "height/2 - PM_SIZE/2"
		var pm := _add_polymino(
			_get_random_pm(), 
			_pm_pos(i), 
			false
		)
		
		var price := _get_pm_price(pm.string)
		var lbl := GridLabel.new(_pm_pos(i) + Vector2i(0, -1), str(price), self)
		add_child(lbl)
		
		selling.append([pm, price, lbl])

func _ready() -> void:
	##spacing/pm/text+spacing/abil+text/spacing
	
	_stock_shop()
	
	extra_buttons.resize(5)
	
	var add_pm_button := ShopButton.new("res://shop_add_pm_icon.png", self, _pm_pos(0, false))
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.ADD_PM] = [Enums.shop_add_pm_price(game.round_num, game.max_pm), add_pm_button]
	add_child(add_pm_button)
	
	var restock_button := ShopButton.new("res://restock.png", self, _pm_pos(1, false))
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.RESTOCK] = [Enums.shop_restock_price(game.round_num, game.max_pm), restock_button]
	add_child(restock_button)
	
	#if game.unlocked_abil_a < game.max_abil_a_size-1:
	var abil_unlock_button := ShopButton.new("res://shop_unlock_abil.png", self, _pm_pos(2, false))
	extra_buttons[Enums.SHOP_EXTRA_BUTTONS.UNLOCK_ACTIVE_ABIL] = [Enums.shop_restock_price(game.round_num, game.max_pm), abil_unlock_button]
	add_child(abil_unlock_button)
	
	game.score_board.Continue.connect(func():
		BoardClear.emit()
	)
	game.score_board.setup_score_board(self)
	
	update_block_list()
	update_position()

func _init(s_x: int = _selling_amount*4 + (_selling_amount+1)*_grid_spacing, s_y: int = 24, scle: float = 1.0) -> void:
	##old: s_y: int = _grid_spacing+4+4+4+_grid_spacing
	height = s_y
	width = s_x
	scale = Vector2(scle, scle)
