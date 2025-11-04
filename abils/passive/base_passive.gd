extends Ability
class_name AbilityPassive

var hook: Signal

static func get_abil_name(name: String) -> Ability:
	return (Enums.ABILITIES_PASSIVE[name.to_lower()].new() if Enums.ABILITIES_PASSIVE[name.to_lower()] else null)
