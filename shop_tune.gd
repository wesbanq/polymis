@tool
class_name ShopTuning
extends Tuning

## round-number scaling for every price below is capped at this point so it doesn't
## run away to MAX_PM_PRICE (or beyond) well before a full playthrough -- same idea as
## GameTuning.last_round, kept separate here so shop pacing can be tuned independently
@export var price_round_cap: int = 100

@export var add_pm_const := 1.1854
@export var restock_const := 1.2695
@warning_ignore_start("shadowed_global_identifier", "narrowing_conversion")

const MAX_PM_PRICE := 999999
func get_pm_price(ps: PolyminoShape, round_num: int) -> int:
	var n := 0
	var m := 0
	var p := 0

	for blk in ps.shape_string:
		if blk is BlockInfo:
			n += 1
			if blk.modifier != null:
				m += 1
				p += blk.modifier.mod_price

	var capped_round := mini(round_num, price_round_cap)
	return clampi(85*round_num + capped_round**(n*.7) + ((p*m)/float(n))**(capped_round*.15), 0, MAX_PM_PRICE)

@export var remove_pm_const: float = 1.6767
func remove_pm_price(round: int, current: int) -> int:
	var capped_round := mini(round, price_round_cap)
	return (remove_pm_const*current + remove_pm_const**2) * remove_pm_const**capped_round

func add_pm_price(round: int, current: int) -> int:
	var capped_round := mini(round, price_round_cap)
	return (add_pm_const*current + add_pm_const**2) * add_pm_const**capped_round

@export var abil_unlock_base_prices: Array[int]
@export var abil_unlock_exp: float = 3.0
func abil_unlock_price(round: int, max_abil: int) -> int:
	return abil_unlock_base_prices[max_abil] * mini(round, price_round_cap)**abil_unlock_exp

func restock_price(round: int, current: int) -> int:
	var capped_round := mini(round, price_round_cap)
	return (restock_const*current + restock_const**2) * restock_const**capped_round
