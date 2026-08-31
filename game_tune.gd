class_name GameTuning
extends Tuning

func sp_from_lines(lines: Array[int], board: GameBoard) -> int:
	var mod_n := 1
	var mod_b := 1
	
	for y in lines:
		for x in board.width:
			if board.block_list[x][y].modifier:
				mod_n += 1
				mod_b += board.block_list[x][y].modifier.sp_bonus
	
	@warning_ignore("narrowing_conversion")
	return board.width * mod_n * lines.size() * mod_b**2 * .25

@export var fall_speed: Curve
@export var last_round: int = 1

@warning_ignore("shadowed_global_identifier")
func falling_speed(round: int) -> float:
	#return 1.59658/(1+exp(1)**(.556572*round - 3.2994))
	#print(fall_speed.sample_baked(clampf(round, 0, last_round) / last_round))
	#print(last_round, " ", clampf(round, 0, last_round) / last_round)
	return fall_speed.sample_baked(clampf(round, 0, last_round) / last_round)
