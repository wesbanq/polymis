@tool
class_name TuningSim
extends RefCounted

## Computes and exports the real Tuner.game / Tuner.shop / Tuner.effects formulas across a
## representative range of inputs, so a formula's whole shape (all rounds at once, not one
## at a time) can be checked without nudging a slider in a live game. Calls the actual Tuning
## resources directly -- never reimplements their math -- so this can't drift out of sync.
##
## Loads the three Tuning resources by path rather than through the Tuner autoload, since
## autoloads only exist while a game is actually running (Play) -- loading by path works
## identically at runtime, from an EditorScript, or from a live editor dock, and resource
## loads are cached by the engine, so this always gets the same live instance the inspector
## is editing, not a stale disk copy.

const REPRESENTATIVE_WIDTH := 10
const OUT_DIR := "res://tuning_sim/"

const GAME_TUNING_PATH := "res://tune/game.tres"
const SHOP_TUNING_PATH := "res://tune/shop.tres"
const EFFECTS_TUNING_PATH := "res://tune/effects.tres"

static func load_game_tuning() -> GameTuning: return load(GAME_TUNING_PATH)
static func load_shop_tuning() -> ShopTuning: return load(SHOP_TUNING_PATH)
static func load_effects_tuning() -> EffectTuning: return load(EFFECTS_TUNING_PATH)

static func _plain_shape(n: int) -> PolyminoShape:
	var shape := PolyminoShape.new()
	for i in n:
		shape.shape_string[i] = BlockInfo.new()
	return shape

static func _modded_shape(n: int, mod_path: String) -> PolyminoShape:
	var shape := PolyminoShape.new()
	for i in n:
		var info := BlockInfo.new()
		info.modifier = load(mod_path).duplicate()
		shape.shape_string[i] = info
	return shape

## one Dictionary[String, Array[Vector2]] entry per plotted series -- x is round_num for
## everything except the two "by clear step" effect series, which don't scale with round_num
## at all and get their own x-axis (progress through a single line-clear sequence)
static func compute_series(max_round: int = 120) -> Dictionary:
	var game_t := load_game_tuning()
	var shop_t := load_shop_tuning()
	var effects_t := load_effects_tuning()

	# two comparison shapes for get_pm_price: a plain 4-block piece, and a single gold-modded
	# block (gold.tres, mod_price=5000 -- the most expensive modifier) to make the modifier
	# compounding term's behavior visible rather than theoretical
	var plain_4 := _plain_shape(4)
	var gold_1 := _modded_shape(1, "res://modifiers/resources/gold.tres")

	var series: Dictionary = {
		"score_goal": [] as Array[Vector2],
		"falling_speed": [] as Array[Vector2],
		"add_pm_price": [] as Array[Vector2],
		"restock_price": [] as Array[Vector2],
		"remove_pm_price": [] as Array[Vector2],
		"abil_unlock_price(tier0)": [] as Array[Vector2],
		"abil_unlock_price(tier2)": [] as Array[Vector2],
		"get_pm_price(4blk,no-mod)": [] as Array[Vector2],
		"get_pm_price(1blk,gold-mod)": [] as Array[Vector2],
	}
	for round_num in range(1, max_round + 1):
		series["score_goal"].append(Vector2(round_num, game_t.score_goal(round_num, REPRESENTATIVE_WIDTH)))
		series["falling_speed"].append(Vector2(round_num, game_t.falling_speed(round_num)))
		series["add_pm_price"].append(Vector2(round_num, shop_t.add_pm_price(round_num, 5)))
		series["restock_price"].append(Vector2(round_num, shop_t.restock_price(round_num, 5)))
		series["remove_pm_price"].append(Vector2(round_num, shop_t.remove_pm_price(round_num, 5)))
		series["abil_unlock_price(tier0)"].append(Vector2(round_num, shop_t.abil_unlock_price(round_num, 0)))
		series["abil_unlock_price(tier2)"].append(Vector2(round_num, shop_t.abil_unlock_price(round_num, 2)))
		series["get_pm_price(4blk,no-mod)"].append(Vector2(round_num, shop_t.get_pm_price(plain_4, round_num)))
		series["get_pm_price(1blk,gold-mod)"].append(Vector2(round_num, shop_t.get_pm_price(gold_1, round_num)))

	var line_width := REPRESENTATIVE_WIDTH
	var flash_span := effects_t.last_flash_line * line_width
	var flash_series: Array[Vector2] = []
	var pitch_series: Array[Vector2] = []
	for step in range(flash_span + 1):
		@warning_ignore("integer_division")
		var line_complete := step / line_width
		var block := step % line_width
		flash_series.append(Vector2(step, effects_t.flash_time(line_complete, block, line_width)))
		pitch_series.append(Vector2(step, effects_t.pitch(line_complete, block, line_width)))
	series["flash_time (by clear step)"] = flash_series
	series["pitch (by clear step)"] = pitch_series

	return series

static func _write_csv(filename: String, header: Array[String], rows: Array[Array]) -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var f := FileAccess.open(OUT_DIR + filename, FileAccess.WRITE)
	f.store_line(",".join(header))
	for row in rows:
		var strs: Array[String] = []
		for v in row:
			strs.append(str(v))
		f.store_line(",".join(strs))
	f.close()

## writes CSVs covering every series from compute_series() -- the entry point used by both
## the "tunesim" in-game console command and the "run in editor" EditorScript
static func run(max_round: int = 120) -> String:
	var series := compute_series(max_round)
	var round_keys: Array[String] = [
		"score_goal", "falling_speed", "add_pm_price", "restock_price", "remove_pm_price",
		"abil_unlock_price(tier0)", "abil_unlock_price(tier2)",
		"get_pm_price(4blk,no-mod)", "get_pm_price(1blk,gold-mod)",
	]
	var rows: Array[Array] = []
	for i in max_round:
		var row: Array = [i + 1]
		for k in round_keys:
			row.append(series[k][i].y)
		rows.append(row)
	var header: Array[String] = ["round"]
	header.append_array(round_keys)
	_write_csv("rounds.csv", header, rows)

	var flash_series: Array[Vector2] = series["flash_time (by clear step)"]
	var pitch_series: Array[Vector2] = series["pitch (by clear step)"]
	var erows: Array[Array] = []
	for i in flash_series.size():
		erows.append([i, flash_series[i].y, pitch_series[i].y])
	_write_csv("effects.csv", ["step", "flash_time", "pitch"], erows)

	return "wrote %d rounds -> %srounds.csv, %d steps -> %seffects.csv" % [max_round, OUT_DIR, flash_series.size(), OUT_DIR]
