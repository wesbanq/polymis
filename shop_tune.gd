class_name ShopTuning
extends Tuning

@export var add_pm_const := 1.1854
@export var restock_const := 1.2695
@warning_ignore_start("shadowed_global_identifier", "narrowing_conversion")

@export var pm_mod_price_curve: Curve
@export var pm_mod_price_const: float
@export var pm_mod_price_const_base: float
@export var pm_size_price_curve: Curve
@export var pm_size_price_const: float
@export var pm_size_price_const_base: float


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
	
	#return clampi(85*round_num + round_num**(n*.7) + ((p*m)/float(n))**(round_num*.15), 0, MAX_PM_PRICE)
	var f1 := pm_size_price_const_base**(pm_size_price_const*pm_size_price_curve.sample_baked(n/16.))
	var f2 := (p/2.) * pm_mod_price_const_base**(pm_mod_price_const*pm_mod_price_curve.sample_baked(m/float(n)))
	print(f1, " ", f2, " ", (round_num/2.))
	return clampi(max(1, f1) * max(1, f2) * (round_num/2.), 1, MAX_PM_PRICE)

@export var remove_pm_const: float
func remove_pm_price(round: int, current: int) -> int:
	current += 1
	return (remove_pm_const*current + remove_pm_const**2) * remove_pm_const**round

func add_pm_price(round: int, current: int) -> int:
	current += 1
	return (add_pm_const*current + add_pm_const**2) * add_pm_const**round

@export var abil_unlock_base_prices: Array[int]
@export var abil_unlock_exp: float = 3.0
func abil_unlock_price(round: int, max_abil: int) -> int:
	return abil_unlock_base_prices[max_abil] * round**abil_unlock_exp

func restock_price(round: int, current: int) -> int:
	return (restock_const*current + restock_const**2) * restock_const**round
