extends Board
class_name ShopBoard

signal BoughtPolymino(ps: PolyminoShape)
@warning_ignore("unused_signal")
signal BoughtAbility
signal BoardClear
signal IncreasedPMCount

@export var _selling_amount := 3
@export var _grid_spacing := 1

const PM_SIZE := 4

@onready var _avail_pieces: Array[PolyminoShape] = _get_avail_pieces("res://polymino_shapes/")
@onready var _ranges: Array[float] = _get_ranges(_avail_pieces)

var _mod_chance: float:
	get: return game.round_num*1.5 + 10
@onready var _avail_mod := _get_avail_mods()
@onready var _mod_ranges: Array[float] = _get_ranges(_avail_mod)

var selling: Array
var extra_buttons: Array

static func _get_avail_pieces(filepath: String) -> Array[PolyminoShape]:
	var result: Array[PolyminoShape] = []
	for v in DirAccess.open(filepath).get_files():
		#duplicate deep so as not to change the original polyminoshape resources
		result.append(load(filepath+v).duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	return result

static func _get_avail_mods() -> Array:
	var result := []
	for c in ProjectSettings.get_global_class_list():
		if c.base == "Modifier" and c.class != "NoModifier" and c.class != "RandomModifier":
			result.append(load(c.path).new())
	return result

static func _get_ranges(weight_src: Array[Variant]) -> Array[float]:
	var result: Array[float]
	#create a list of ranges all corresponding to a polymino
	#the length of a ranges is determined by the polyminos weight	
	for v in weight_src:
		result.append(v.weight + (result[-1] if result.size() > 0 else 0.))
	return result

@warning_ignore("shadowed_variable")
static func _get_random_pm(_mod_ranges: Array[float], _avail_mod: Array, _ranges: Array[float], _avail_pieces: Array[PolyminoShape], _mod_chance: float) -> PolyminoShape:
	var shape = RNG.pick_random_weight(_ranges, _avail_pieces)
	var new_color := RNG.get_random_color()
	
	for blk in shape.shape_string:
		if blk is BlockInfo:
			blk.color = new_color
			if RNG.randi(0, 100) <= _mod_chance:
				blk.modifier = RNG.pick_random_weight(_mod_ranges, _avail_mod)
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
	
	#print(n,m,p,game.round_num)
	@warning_ignore("narrowing_conversion")
	return clampi(85*game.round_num + game.round_num**(n*.7) + ((p*m)/float(n))**(game.round_num*.15), 0, 999999)
	#return 999999

func purchase(idx: int, blks: bool = true) -> void:
	if blks:
		if game.pts >= selling[idx][1]:
			game.bag.add_to_bag(selling[idx][0].string)
			game.pts -= selling[idx][1]
			BoughtPolymino.emit(selling[idx][0].string)
			selling[idx][0].destroy()
			selling[idx] = null
		else:
			print("player has: %d, cost: %d" % [game.pts, selling[idx][1]])
	else:
		if game.pts >= extra_buttons[idx][0]:
			match idx:
				#add pm
				0:
					game.pts -= extra_buttons[0][0]
					game.max_pm += 1
					IncreasedPMCount.emit()
					extra_buttons[0][1].destroy()
					extra_buttons[0][0] = Enums.shop_add_pm_price(game.round_num, game.max_pm)
					extra_buttons[0][1] = ShopButton.new("res://shop_add_pm_icon.png", self)
					add_child(extra_buttons[0][1])
					#sends signal to score board to change pm value
					#TODO crutch pls fix
					if game.score_board:
						game.score_board.ChangeNumber.emit(game.max_pm, Enums.SCORE_BOARD.PM_LEFT)
				#active abils
				1:
					pass
				#passive abils
				2:
					pass
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
		
		
		if extra_buttons[0][1].click_within_block(world_pos) and extra_buttons[0][0] <= game.pts:
			purchase(0, false)

func _pm_pos(i: int, a: bool = true) -> Vector2i:
	return Vector2i(i*PM_SIZE + (i+1)*_grid_spacing + 1, height - height/3 if a else height/3)
	#return Vector2i(i*PM_SIZE + (i+1)*_grid_spacing + 1, height/2)

func _ready() -> void:
	#width = _selling_amount*4 + (_selling_amount-1)*_grid_spacing
	#height = _grid_spacing+4+4+4+_grid_spacing
	##spacing/pm/text+spacing/abil+text/spacing
	
	for i in range(_selling_amount):
		#TODO wacky behaviour w/ "height/2 - PM_SIZE/2"
		var pm := _add_polymino(
			_get_random_pm(_mod_ranges, _avail_mod, _ranges, _avail_pieces, _mod_chance), 
			_pm_pos(i), 
			false)
		
		selling.append([pm, _get_pm_price(pm.string)])
		
		var lbl := RichTextLabel.new()
		lbl.text = str(selling[-1][1])
		lbl.theme = load("res://text.tres")
		
		#TODO MOVE LABELS IN TANDEM W/ GRID SCALING
		
		#TEMP REMOVE L8R
		#VVVVV
		#offset label from corrseponding block by 1 grid space
		lbl.position = Block.get_position_from_grid(_pm_pos(i) + Vector2i(0, -1), self)
		lbl.theme = load("res://text.tres")
		lbl.custom_minimum_size = Vector2(120,120)
		#^^^^^
		
		add_child(lbl)
	
	var add_pm_button := ShopButton.new("res://shop_add_pm_icon.png", self)
	extra_buttons.insert(0, [Enums.shop_add_pm_price(game.round_num, game.max_pm), add_pm_button])
	add_child(add_pm_button)
	
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
