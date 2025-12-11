extends Resource
class_name CardData

# Alchemical element types
enum ElementType {
	SULFUR,    # Fire/Destruction
	MERCURY,   # Liquid/Transformation
	SALT,      # Earth/Stability
	VITAE,     # Life/Growth
	AETHER     # Spirit/Energy
}

# Card rarity (for future progression)
enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# Effect types that cards can have
enum EffectType {
	DAMAGE,
	HEAL,
	BLOCK,
	DRAW,
	SPECIAL
}

# Basic card properties
@export var card_name: String = ""
@export var description: String = ""
@export var element: ElementType = ElementType.SULFUR
@export var rarity: Rarity = Rarity.COMMON

# Effect data - cards can have multiple effects
@export var effects: Array[CardEffect] = []

# Diablo-style random roll ranges (min-max for drops)
@export var damage_range: Vector2i = Vector2i(0, 0)  # e.g., Vector2i(3, 7) = 3-7 damage
@export var heal_range: Vector2i = Vector2i(0, 0)
@export var block_range: Vector2i = Vector2i(0, 0)
@export var draw_amount: int = 0

# Actual rolled values (set when card is created/dropped)
var damage_value: int = 0
var heal_value: int = 0
var block_value: int = 0

# Combo bonuses
@export var combo_damage_bonus: int = 0
@export var combo_heal_bonus: int = 0
@export var combo_block_bonus: int = 0

# Special conditions
@export var bonus_if_facing_empty: bool = false
@export var bonus_if_adjacent_empty: bool = false
@export var ignores_block: bool = false

# Visual
@export var card_art: Texture2D  # Sprite for the card

# Initialize with random rolls
func roll_stats() -> void:
	if damage_range.x > 0 or damage_range.y > 0:
		damage_value = randi_range(damage_range.x, damage_range.y)
	if heal_range.x > 0 or heal_range.y > 0:
		heal_value = randi_range(heal_range.x, heal_range.y)
	if block_range.x > 0 or block_range.y > 0:
		block_value = randi_range(block_range.x, block_range.y)

# Get element color for UI
func get_element_color() -> Color:
	match element:
		ElementType.SULFUR:
			return Color.ORANGE_RED  # Fire
		ElementType.MERCURY:
			return Color.STEEL_BLUE  # Liquid
		ElementType.SALT:
			return Color.SADDLE_BROWN  # Earth
		ElementType.VITAE:
			return Color.LIME_GREEN  # Life
		ElementType.AETHER:
			return Color.MEDIUM_PURPLE  # Spirit
	return Color.WHITE

# Get element name as string
func get_element_name() -> String:
	match element:
		ElementType.SULFUR:
			return "Sulfur"
		ElementType.MERCURY:
			return "Mercury"
		ElementType.SALT:
			return "Salt"
		ElementType.VITAE:
			return "Vitae"
		ElementType.AETHER:
			return "Aether"
	return "Unknown"

# Create a copy of this card with new random rolls
func create_instance() -> CardData:
	var instance = self.duplicate(true)
	instance.roll_stats()
	return instance
