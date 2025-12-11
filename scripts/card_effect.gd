extends Resource
class_name CardEffect

# Effect types
enum Type {
	DAMAGE,
	HEAL,
	BLOCK,
	DRAW,
	COPY_ADJACENT,
	COPY_FACING,
	POSITION_SWAP,
	CUSTOM
}

@export var effect_type: Type = Type.DAMAGE
@export var base_value: int = 0
@export var combo_bonus: int = 0

# Conditions
@export var requires_facing_empty: bool = false
@export var requires_adjacent_empty: bool = false
@export var requires_combo: bool = false
@export var ignores_block: bool = false

# For special effects
@export var custom_effect_id: String = ""  # e.g., "echo_leftmost", "volatile_catalyst"

# Calculate final value based on conditions
func calculate_value(is_in_combo: bool, facing_is_empty: bool, adjacent_is_empty: bool) -> int:
	var value = base_value
	
	if is_in_combo and combo_bonus > 0:
		value += combo_bonus
	
	if requires_facing_empty and facing_is_empty:
		value *= 2  # or add bonus, customize as needed
	
	if requires_adjacent_empty and adjacent_is_empty:
		value += 3  # customize bonus
	
	return value
