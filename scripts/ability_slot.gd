extends Resource
class_name AbilitySlot

# Reference to the ability type definition (loaded from .tres file)
@export var ability_type: AbilityType

# The randomly rolled value for this specific card instance
# This is set when the card is created/dropped and persists for the card's lifetime
@export var rolled_value: int = 0

# Roll the value based on the card's rarity
func roll_value(rarity: int) -> void:
	if ability_type:
		rolled_value = ability_type.roll_value(rarity)
	else:
		push_warning("AbilitySlot.roll_value: No ability_type set")
		rolled_value = 0

# Get the description for this ability with the rolled value
func get_description() -> String:
	if ability_type:
		return ability_type.get_description(rolled_value)
	return ""

# Get the ability's unique identifier
func get_id() -> String:
	if ability_type:
		return ability_type.id
	return ""

# Get the ability's category
func get_category() -> AbilityType.EffectCategory:
	if ability_type:
		return ability_type.category
	return AbilityType.EffectCategory.CUSTOM

# Check if this is a boolean ability (no numeric value)
func is_boolean() -> bool:
	if ability_type:
		return ability_type.is_boolean
	return false

# Serialize for save/load
func to_dict() -> Dictionary:
	return {
		"ability_id": ability_type.id if ability_type else "",
		"rolled_value": rolled_value
	}

# Deserialize from saved data
# Note: Requires AbilityRegistry to look up the ability_type by id
func from_dict(data: Dictionary, ability_registry) -> void:
	var ability_id = data.get("ability_id", "")
	if ability_id != "" and ability_registry:
		ability_type = ability_registry.get_ability(ability_id)
	rolled_value = data.get("rolled_value", 0)

# Create a duplicate of this slot (for card duplication)
func duplicate_slot() -> AbilitySlot:
	var new_slot = AbilitySlot.new()
	new_slot.ability_type = ability_type  # Same reference is fine, it's immutable
	new_slot.rolled_value = rolled_value
	return new_slot
