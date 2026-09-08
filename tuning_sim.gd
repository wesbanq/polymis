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

## every argument any formula takes, with the hard limits a control should allow, the value to
## hold it at when it isn't the swept axis, and the default domain to sweep it over when it is
const ARGS := {
	"round":     {"min": 1, "max": 200, "default": 10, "domain": [1, 120]},
	"step":      {"min": 0, "max": 400, "default": 0,  "domain": [0, 10]},  # recomputed, see default_domain()
	"width":     {"min": 4, "max": 20,  "default": REPRESENTATIVE_WIDTH, "domain": [4, 20]},
	"current":   {"min": 0, "max": 30,  "default": 5,  "domain": [0, 30]},
	"abil_tier": {"min": 0, "max": 2,   "default": 0,  "domain": [0, 2]},
}

## which arguments each formula actually takes, and which one it sweeps by default. Any of a
## series' args can be made the x-axis; the rest are held at their fixed values. get_pm_price's
## other input is the shape itself rather than a scalar, so it isn't listed as a sweepable arg
## -- the two variants below are fixed plain/gold-modded comparison cases instead.
const SERIES_DEFS := {
	"score_goal":                  {"x": "round", "args": ["round", "width"]},
	"falling_speed":               {"x": "round", "args": ["round"]},
	"add_pm_price":                {"x": "round", "args": ["round", "current"]},
	"restock_price":               {"x": "round", "args": ["round", "current"]},
	"remove_pm_price":             {"x": "round", "args": ["round", "current"]},
	"abil_unlock_price":           {"x": "round", "args": ["round", "abil_tier"]},
	"get_pm_price(4blk,no-mod)":   {"x": "round", "args": ["round"]},
	"get_pm_price(1blk,gold-mod)": {"x": "round", "args": ["round"]},
	"flash_time (by clear step)":  {"x": "step",  "args": ["step", "width"]},
	"pitch (by clear step)":       {"x": "step",  "args": ["step", "width"]},
}

## resources + comparison shapes, built once per sweep instead of per evaluated point
static func _make_ctx() -> Dictionary:
	return {
		"game": load_game_tuning(),
		"shop": load_shop_tuning(),
		"effects": load_effects_tuning(),
		# a plain 4-block piece and a single gold-modded block (gold.tres, mod_price=5000 --
		# the most expensive modifier), so get_pm_price's modifier compounding term is visible
		# rather than theoretical
		"plain_4": _plain_shape(4),
		"gold_1": _modded_shape(1, "res://modifiers/resources/gold.tres"),
	}

## fills in every argument not explicitly supplied with its held-fixed default, so a caller
## can pass only what it cares about without a missing key crashing an evaluation
static func _full_args(args: Dictionary) -> Dictionary:
	var out := {}
	for k in ARGS:
		out[k] = int(args.get(k, ARGS[k]["default"]))
	return out

## the single place a formula is actually called -- every series, every entry point (chart,
## CSV, console) routes through here, so no code path can evaluate a formula differently
static func _eval(series_name: String, a: Dictionary, ctx: Dictionary) -> float:
	match series_name:
		"score_goal":
			return ctx["game"].score_goal(a["round"], a["width"])
		"falling_speed":
			return ctx["game"].falling_speed(a["round"])
		"add_pm_price":
			return ctx["shop"].add_pm_price(a["round"], a["current"])
		"restock_price":
			return ctx["shop"].restock_price(a["round"], a["current"])
		"remove_pm_price":
			return ctx["shop"].remove_pm_price(a["round"], a["current"])
		"abil_unlock_price":
			return ctx["shop"].abil_unlock_price(a["round"], a["abil_tier"])
		"get_pm_price(4blk,no-mod)":
			return ctx["shop"].get_pm_price(ctx["plain_4"], a["round"])
		"get_pm_price(1blk,gold-mod)":
			return ctx["shop"].get_pm_price(ctx["gold_1"], a["round"])
		"flash_time (by clear step)":
			var w: int = a["width"]
			@warning_ignore("integer_division")
			var line_complete: int = a["step"] / w
			return ctx["effects"].flash_time(line_complete, a["step"] % w, w)
		"pitch (by clear step)":
			var w: int = a["width"]
			@warning_ignore("integer_division")
			var line_complete: int = a["step"] / w
			return ctx["effects"].pitch(line_complete, a["step"] % w, w)
	push_error("unknown tuning series: %s" % series_name)
	return 0.0

## sensible sweep range for an argument. "step" is the odd one out: how many blocks a clear
## sequence covers depends on last_flash_line and the board width, so it's derived rather than
## a fixed pair -- this is what makes the domain change with the simulation being viewed
static func default_domain(arg_name: String, args: Dictionary = {}) -> Vector2i:
	if arg_name == "step":
		var a := _full_args(args)
		return Vector2i(0, maxi(1, load_effects_tuning().last_flash_line * int(a["width"])))
	var d: Array = ARGS[arg_name]["domain"]
	return Vector2i(int(d[0]), int(d[1]))

## sweeps one series' chosen argument across [x_min, x_max], holding every other argument at
## the value given in `args` (or its default)
static func compute_one(series_name: String, x_arg: String, x_min: int, x_max: int, args: Dictionary = {}) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if x_max < x_min:
		return out
	var ctx := _make_ctx()
	var a := _full_args(args)
	for x in range(x_min, x_max + 1):
		a[x_arg] = x
		out.append(Vector2(x, _eval(series_name, a, ctx)))
	return out

## every series at once, each swept over its own default axis -- used for the CSV dump
static func compute_series(max_round: int = 120, width: int = REPRESENTATIVE_WIDTH, current: int = 5, abil_tier: int = 0) -> Dictionary:
	var ctx := _make_ctx()
	var base := {"width": width, "current": current, "abil_tier": abil_tier}
	var step_domain := default_domain("step", base)

	var series: Dictionary = {}
	for series_name in SERIES_DEFS:
		var x_arg: String = SERIES_DEFS[series_name]["x"]
		var a := _full_args(base)
		var pts: Array[Vector2] = []
		var lo := 1 if x_arg == "round" else step_domain.x
		var hi := max_round if x_arg == "round" else step_domain.y
		for x in range(lo, hi + 1):
			a[x_arg] = x
			pts.append(Vector2(x, _eval(series_name, a, ctx)))
		series[series_name] = pts
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
static func run(max_round: int = 120, width: int = REPRESENTATIVE_WIDTH, current: int = 5, abil_tier: int = 0) -> String:
	var series := compute_series(max_round, width, current, abil_tier)
	var round_keys: Array[String] = []
	for series_name in SERIES_DEFS:
		if SERIES_DEFS[series_name]["x"] == "round":
			round_keys.append(series_name)
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
