extends Node

# Singleton that loads and provides access to all AbilityType resources
# Add to Project Settings -> Autoload as "AbilityRegistry"

# Dictionary mapping ability id -> AbilityType resource
var abilities: Dictionary = {}

const ABILITIES_PATH = "res://assets/abilities/"

func _ready() -> void:
	_load_all_abilities()

# Load all .tres files from the abilities directory
func _load_all_abilities() -> void:
	abilities.clear()
	
	var dir = DirAccess.open(ABILITIES_PATH)
	if not dir:
		push_warning("AbilityRegistry: Could not open abilities directory at %s" % ABILITIES_PATH)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = ABILITIES_PATH + file_name
			var ability = load(full_path) as AbilityType
			if ability:
				if ability.id == "":
					push_warning("AbilityRegistry: Ability in %s has no id set" % file_name)
				else:
					abilities[ability.id] = ability
					print("[AbilityRegistry] Loaded ability: %s" % ability.id)
			else:
				push_warning("AbilityRegistry: Failed to load ability from %s" % file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("[AbilityRegistry] Loaded %d abilities" % abilities.size())

# Get an ability by its unique id
func get_ability(id: String) -> AbilityType:
	if id in abilities:
		return abilities[id]
	push_warning("AbilityRegistry: Unknown ability id: %s" % id)
	return null

# Check if an ability exists
func has_ability(id: String) -> bool:
	return id in abilities

# Get all loaded ability ids
func get_all_ability_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in abilities.keys():
		ids.append(key)
	return ids

# Get all abilities of a specific category
func get_abilities_by_category(category: AbilityType.EffectCategory) -> Array[AbilityType]:
	var result: Array[AbilityType] = []
	for ability in abilities.values():
		if ability.category == category:
			result.append(ability)
	return result

# Reload all abilities (useful for development/hot-reloading)
func reload_abilities() -> void:
	print("[AbilityRegistry] Reloading abilities...")
	_load_all_abilities()
