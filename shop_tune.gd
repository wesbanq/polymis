class_name ShopTuning
extends Tuning

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
	
	return clampi(85*round_num + round_num**(n*.7) + ((p*m)/float(n))**(round_num*.15), 0, MAX_PM_PRICE)

@export var remove_pm_const: float = 1.6767
func remove_pm_price(round: int, current: int) -> int:
	return (remove_pm_const*current + remove_pm_const**2) * remove_pm_const**round

func add_pm_price(round: int, current: int) -> int:
	return (add_pm_const*current + add_pm_const**2) * add_pm_const**round

@export var abil_unlock_base_prices: Array[int]
@export var abil_unlock_exp: float = 3.0
func abil_unlock_price(round: int, max_abil: int) -> int:
	return abil_unlock_base_prices[max_abil] * round**abil_unlock_exp

func restock_price(round: int, current: int) -> int:
	return (restock_const*current + restock_const**2) * restock_const**round
