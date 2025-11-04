extends Ability
class_name AbilityActive

@export var sp_cost := 0

func trigger() -> bool:
	return false

static func get_abil_name(name: String):
	return (Enums.ABILITIES_ACTIVE[name.to_lower()] if Enums.ABILITIES_ACTIVE.keys().find(name.to_lower()) != -1 else null)
