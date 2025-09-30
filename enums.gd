extends Node

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

const POLYMINO_SHAPES := [
	#1: rotation center 2: bottom blocks array[1st one is the lowest] 3+: blocks
	#"i 4567 4 5 6 7",	
	"p 1 d 9 5 1",		#4 straight
	"i 01 0 1 4 5",		#4 cube
	"o 016 0 1 5 6",	#4 skew
	"o 142 4 5 1 2",	#4 skew m
	"o 12 9 5 1 2",		#4 l
	"o 01 9 5 1 0",		#4 l m
]

var MODIFIERS := {
	"": null,
	"random": RandomModifier,
	"bonus": BonusModifier,
	"chain": ChainModifier,
	"gold": GoldModifier,
	"armored": ArmoredModifier,
}

enum SCORE_BOARD {
	ROUND_NUM,
	PM_LEFT,
	SCORE_GOAL,
	SCORE_CURRENT,
	PTS_ADDED,
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
