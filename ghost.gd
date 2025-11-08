extends Polymino
class_name Ghost

var master_polymino: Polymino
var ghost_texture = preload("res://ghost_block.png")

signal UpdateGhost

func move(direction: Vector2i) -> void:
	if not check_collision(direction):
		for v in blocks:
			if v is Block:
				v.board_position += direction
				#if ghost: ghost.UpdateGhost.emit()

func _ready() -> void: pass

func update() -> void:
	var old = get_children()
	copy_blocks(master_polymino)
	for i in blocks.size():
		if blocks[i] is Block and master_polymino.blocks[i] is Block:
			blocks[i].board_position = master_polymino.blocks[i].board_position
			blocks[i].material.set_shader_parameter("tint", get_shader_args(blocks[i]))
	for v in old: v.queue_free()
	snap_down()
	for v in blocks: if v is Block: add_child(v)

##FIX reuse blocks when updating ghost instead of recreating them
##VVVVVV
#func apply_turn(delta: Array[Vector2i], shift: int) -> void:
	##TODO FIX ME
	#var new_blocks: Array[Block] = []
	#new_blocks.resize(16)
	#
	#for i in blocks.size():
		#var v = blocks[i]
		#if v is Block:
			#print(i, delta[i],i - PolyminoShape.get_hex_from_board_position(delta[i]))
			#new_blocks[i - PolyminoShape.get_hex_from_board_position(delta[i])] = v
			##print(i, delta[i], PolyminoShape.get_hex_from_board_position(PolyminoShape.get_board_position_from_hex(i) + delta[i]))
			#v.board_position += delta[i]
			#v.board_position.x += shift
	#
	#blocks = new_blocks
	#bottom = calculate_bottom()
	#bottom2 = calculate_bottom2()
	#print(bottom,bottom2)
#func update() -> void:
	##print(blocks,master_polymino.blocks)
	#for i in blocks.size():
		#if blocks[i] is Block and master_polymino.blocks[i] is Block:
			##print(i)
			#blocks[i].board_position = master_polymino.blocks[i].board_position
	#snap_down()
##^^^^^^
##^^^^^^

static func get_shader_args(v) -> Vector4:
	return Vector4(v.color.r*.75, v.color.g*.75, v.color.b*.75, .8)

func _init(master: Polymino = null) -> void:
	master_polymino = master
	super(master_polymino.string, master_polymino.game_board)
	
	for v in blocks:
		if v is Block:
			#v.texture = ghost_texture
			v.material.set_shader_parameter("tint", get_shader_args(v))
			#v.material.set_shader_parameter("tint", Vector4(1, 1, 1, .8))
	
	UpdateGhost.connect(update)
	#game_board.Scored.connect(func(_n): update())
	master_polymino.game_board.add_child(self)
	update()
