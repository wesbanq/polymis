extends Node

@warning_ignore("shadowed_global_identifier")
func between(min: int, max: int, val: int) -> bool:
	return min <= val and max >= val

func read_folder_paths(path: String) -> Array[String]:
	var result: Array[String] = []
	for file_path in DirAccess.get_files_at(path):
		result.append(path.path_join(file_path))
	return result

func read_folder_dict(path: String) -> Dictionary[String, String]:
	var initial := read_folder_paths(path)
	var dict: Dictionary[String, String]
	for i in initial.size():
		var v := initial[i]
		dict[v.get_file().get_slice(".", 0)] = v
	return dict

@warning_ignore("shadowed_global_identifier")
func shop_add_pm_price(round: int, current: int) -> int:
	const c := 1.1854
	@warning_ignore("narrowing_conversion")
	return (c*current + c**2) * c**round

@warning_ignore("shadowed_global_identifier")
func shop_restock_price(round: int, current: int) -> int:
	const c := 1.0924
	@warning_ignore("narrowing_conversion")
	return (c*current + c**2) * c**round

const UI := {
	"END": "[/color]",
	"SP": Color("#c8c800"),
	"ACTIVE_ABIL_ICON_P": Color("#4cffbf"),
	"INACTIVE_ABIL_ICON_P": Color("#1e664c"),
	"ACTIVE_ABIL_ICON_A": Color("#ffffff"),
	"INACTIVE_ABIL_ICON_A": Color("#595959"),
	
	"UNAVAIL_TEXT": Color("#595959"),
	"NORMAL_TEXT": Color("#ffffff"),
	
	"DOWNSIDE_TEXT": Color("#ff0000"),
	"UPSIDE_TEXT": Color("#00ff00"),
	"WARN_TEXT": Color("#ffff00"),
	
	"TEXT_THEME": preload("res://text.tres"),
	"INACTIVE_SHADER": preload("res://inactive.gdshader"),
}

const COLORS := {
	"WHITE": Color("#ffffff"),
	#"BLACK": Color("#000000"),
	#"GRAY": Color("#4c4c4c"),
	"RED": Color("#ff0000"),
	"BLUE": Color("#0000ff"),
	"GREEN": Color("#00ff00"),
	"YELLOW": Color("#ffff00"),
	"CYAN": Color("#00ffff"),
	"MAGENTA": Color("#ff00ff"),
}

const MODIFIER_FOLDER_PATH := "res://modifiers/resources/"
const BAGS_FOLDER := "res://preset_bags/"

var MODIFIERS_PATHS := read_folder_dict(MODIFIER_FOLDER_PATH)
var BAG_PATHS := read_folder_paths(BAGS_FOLDER)

#var MODIFIERS := {
	##"": null,
	#"random": RandomModifier,
	#"bonus": BonusModifier,
	#"chain": ChainModifier,
	#"gold": GoldModifier,
	#"armored": ArmoredModifier,
	#"glass": GlassModifier
#}

var ABILITIES_ACTIVE := {
	"makestraight": MakeStraight,
	"removelast": RemoveLast,
	"noabil": NoAbility,
}

var ABILITIES_PASSIVE := {
	
}

enum SCORE_BOARD {
	ROUND_NUM,
	PM_LEFT,
	SCORE_GOAL,
	SCORE_CURRENT,
	PTS_ADDED,
}

enum ABIL_BOARD {
	SP,
	ABIL_1,
	ABIL_2,
	ABIL_3,
}

enum SHOP_EXTRA_BUTTONS {
	ADD_PM,
	RESTOCK,
	UNLOCK_ACTIVE_ABIL,
	UNLOCK_PASSIVE_ABIL,
	REMOVE_PM,
}

enum BOARD_FINISH {
	WIN_CONTINUE,
	WIN_PM_LEFT,
	LOSE_PM_LEFT,
	LOSE_NO_SPACE,
}

enum GAME_STATE {
	SHOP,
	GAME,
	SG_TRANSITION,
	GS_TRANSITION,
}

enum ROTATION_CENTER {
	TWO = 2,
	THREE = 3,
	FOUR = 4,
}
