class_name GameTuning
extends Tuning

func sp_from_lines(lines: Array[int], width: int, block_list: Array[Array]) -> int:
	var mod_n := 1
	var mod_b := 1
	
	for y in lines:
		for x in width:
			if block_list[x][y].modifier:
				mod_n += 1
				mod_b += block_list[x][y].modifier.sp_bonus
	
	@warning_ignore("narrowing_conversion")
	return width * mod_n * lines.size() * mod_b**2 * .25

@warning_ignore("shadowed_global_identifier", "unused_parameter")
func round_reward(total: int, goal: int, round: int) -> int:
	@warning_ignore("integer_division")
	return max(0, (total-goal) / 10)

func score_goal(round_num: int, width: int) -> int:
	return round_num * (width*100)

@export var fall_speed: Curve
@export var last_round: int = 1

@warning_ignore("shadowed_global_identifier")
func falling_speed(round: int) -> float:
	#return 1.59658/(1+exp(1)**(.556572*round - 3.2994))
	#print(fall_speed.sample_baked(clampf(round, 0, last_round) / last_round))
	#print(last_round, " ", clampf(round, 0, last_round) / last_round)
	return fall_speed.sample_baked(clampf(round, 0, last_round) / last_round)
