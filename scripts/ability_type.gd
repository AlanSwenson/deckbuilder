extends Resource
class_name AbilityType

# How this ability is processed by the game
enum EffectCategory {
	DAMAGE,      # Deals damage to opponent
	HEAL,        # Restores HP
	BLOCK,       # Reduces incoming damage
	DRAW,        # Draw cards
	MODIFIER,    # Modifies other abilities (combo bonus, ignores block)
	CUSTOM       # Requires special handling in code
}

# Unique identifier for this ability (e.g., "fire_damage", "heal", "burn")
@export var id: String = ""

# Display name shown in UI (e.g., "Fire Damage", "Heal")
@export var display_name: String = ""

# Template for generating descriptions. Use {value} as placeholder.
# e.g., "Deal {value} fire damage", "Restore {value} HP"
@export var description_template: String = ""

# Category determines how the game processes this ability
@export var category: EffectCategory = EffectCategory.DAMAGE

# For abilities like "ignores_block" that are either active or not (no numeric value)
@export var is_boolean: bool = false

# Value ranges indexed by Rarity: [COMMON, UNCOMMON, RARE, EPIC, LEGENDARY]
# Each Vector2i represents (min, max) roll range for that rarity
# Example: [(5,8), (7,11), (10,15), (14,20), (18,25)]
@export var value_ranges: Array[Vector2i] = [
	Vector2i(1, 3),   # Common
	Vector2i(2, 5),   # Uncommon
	Vector2i(4, 7),   # Rare
	Vector2i(6, 10),  # Epic
	Vector2i(9, 14)   # Legendary
]

# Roll a random value based on the card's rarity
func roll_value(rarity: int) -> int:
	if is_boolean:
		return 1  # Boolean abilities are always "active" when present
	
	# Ensure rarity is within bounds
	if rarity < 0 or rarity >= value_ranges.size():
		push_warning("AbilityType.roll_value: Invalid rarity %d for ability %s" % [rarity, id])
		rarity = clampi(rarity, 0, value_ranges.size() - 1)
	
	var range_for_rarity = value_ranges[rarity]
	return randi_range(range_for_rarity.x, range_for_rarity.y)

# Generate a description string with the actual value filled in
func get_description(value: int) -> String:
	if is_boolean:
		return description_template  # Boolean abilities don't have a value
	return description_template.replace("{value}", str(value))

# Get the value range for a specific rarity (for UI display)
func get_range_for_rarity(rarity: int) -> Vector2i:
	if rarity < 0 or rarity >= value_ranges.size():
		return Vector2i(0, 0)
	return value_ranges[rarity]
