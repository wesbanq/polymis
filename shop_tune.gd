class_name ShopTuning
extends Tuning

@export var add_pm_const := 1.1854
@export var restock_const := 1.0924

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
	
	@warning_ignore("narrowing_conversion")
	return clampi(85*round_num + round_num**(n*.7) + ((p*m)/float(n))**(round_num*.15), 0, 999999)

@warning_ignore("shadowed_global_identifier")
func add_pm_price(round: int, current: int) -> int:
	@warning_ignore("narrowing_conversion")
	return (add_pm_const*current + add_pm_const**2) * add_pm_const**round

@warning_ignore("shadowed_global_identifier")
func restock_price(round: int, current: int) -> int:
	@warning_ignore("narrowing_conversion")
	return (restock_const*current + restock_const**2) * restock_const**round
