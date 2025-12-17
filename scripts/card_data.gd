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

# Card rarity - determines number of active ability slots and value ranges
# Common: 1 slot, Uncommon: 2 slots, Rare: 3 slots, Epic: 4 slots, Legendary: 5 slots
enum Rarity {
	COMMON,     # 1 ability slot
	UNCOMMON,   # 2 ability slots
	RARE,       # 3 ability slots
	EPIC,       # 4 ability slots
	LEGENDARY   # 5 ability slots
}

# Basic card properties
@export var card_name: String = ""
@export var description: String = ""
@export var element: ElementType = ElementType.SULFUR
@export var rarity: Rarity = Rarity.COMMON
@export var burnable: bool = true  # Whether this card can be destroyed/removed from collection
@export var enabled: bool = true  # Whether this card should be loaded into the game (for testing one card at a time)

# Ability slots - each card can have up to 5 abilities
# Only slots up to get_slot_count() are active based on rarity
@export var ability_slots: Array[AbilitySlot] = []

# Visual
@export var card_art: Texture2D  # Sprite for the card

# Get the number of active ability slots based on rarity
func get_slot_count() -> int:
	return rarity + 1  # COMMON=0 -> 1 slot, LEGENDARY=4 -> 5 slots

# Roll stats for all active ability slots based on rarity
func roll_stats() -> void:
	var active_slots = get_slot_count()
	for i in range(mini(active_slots, ability_slots.size())):
		ability_slots[i].roll_value(rarity)

# Add an ability to this card by id (convenience method)
func add_ability(ability_id: String) -> void:
	var ability_type = AbilityRegistry.get_ability(ability_id)
	if ability_type:
		var slot = AbilitySlot.new()
		slot.ability_type = ability_type
		ability_slots.append(slot)
	else:
		push_warning("CardData.add_ability: Unknown ability id: %s" % ability_id)

# Get the rolled value for a specific ability by id
func get_ability_value(ability_id: String) -> int:
	var active_slots = get_slot_count()
	for i in range(mini(active_slots, ability_slots.size())):
		var slot = ability_slots[i]
		if slot.ability_type and slot.ability_type.id == ability_id:
			return slot.rolled_value
	return 0

# Check if this card has a specific ability (and it's active based on rarity)
func has_ability(ability_id: String) -> bool:
	var active_slots = get_slot_count()
	for i in range(mini(active_slots, ability_slots.size())):
		var slot = ability_slots[i]
		if slot.ability_type and slot.ability_type.id == ability_id:
			return true
	return false

# Get total damage from all active DAMAGE category abilities
func get_total_damage() -> int:
	var total = 0
	var active_slots = get_slot_count()
	for i in range(mini(active_slots, ability_slots.size())):
		var slot = ability_slots[i]
		if slot.ability_type and slot.ability_type.category == AbilityType.EffectCategory.DAMAGE:
			total += slot.rolled_value
	return total

# Get total heal from all active HEAL category abilities
func get_total_heal() -> int:
	var total = 0
	var active_slots = get_slot_count()
	for i in range(mini(active_slots, ability_slots.size())):
		var slot = ability_slots[i]
		if slot.ability_type and slot.ability_type.category == AbilityType.EffectCategory.HEAL:
			total += slot.rolled_value
	return total

# Get total block from all active BLOCK category abilities
func get_total_block() -> int:
	var total = 0
	var active_slots = get_slot_count()
	for i in range(mini(active_slots, ability_slots.size())):
		var slot = ability_slots[i]
		if slot.ability_type and slot.ability_type.category == AbilityType.EffectCategory.BLOCK:
			total += slot.rolled_value
	return total

# Get total draw from all active DRAW category abilities
func get_total_draw() -> int:
	var total = 0
	var active_slots = get_slot_count()
	for i in range(mini(active_slots, ability_slots.size())):
		var slot = ability_slots[i]
		if slot.ability_type and slot.ability_type.category == AbilityType.EffectCategory.DRAW:
			total += slot.rolled_value
	return total

# Check if this card ignores block
func ignores_block() -> bool:
	return has_ability("ignores_block")

# Get combo damage bonus
func get_combo_damage() -> int:
	return get_ability_value("combo_damage")

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

# Get rarity name as string
func get_rarity_name() -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.UNCOMMON:
			return "Uncommon"
		Rarity.RARE:
			return "Rare"
		Rarity.EPIC:
			return "Epic"
		Rarity.LEGENDARY:
			return "Legendary"
	return "Unknown"

# Get rarity color for UI
func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON:
			return Color.GRAY
		Rarity.UNCOMMON:
			return Color.GREEN
		Rarity.RARE:
			return Color.DODGER_BLUE
		Rarity.EPIC:
			return Color.DARK_VIOLET
		Rarity.LEGENDARY:
			return Color.ORANGE
	return Color.WHITE

# Generate description from active ability slots
func generate_description() -> String:
	var parts: Array[String] = []
	var active_slots = get_slot_count()
	for i in range(mini(active_slots, ability_slots.size())):
		var slot = ability_slots[i]
		if slot.ability_type:
			parts.append(slot.get_description())
	return ". ".join(parts)

# Create a copy of this card with new random rolls
func create_instance() -> CardData:
	var instance = CardData.new()
	instance.card_name = card_name
	instance.description = description
	instance.element = element
	instance.rarity = rarity
	instance.card_art = card_art
	instance.enabled = enabled
	
	# Deep copy ability slots
	for slot in ability_slots:
		var new_slot = slot.duplicate_slot()
		instance.ability_slots.append(new_slot)
	
	# Roll new values
	instance.roll_stats()
	return instance

# Serialize for save/load
func to_save_dict() -> Dictionary:
	var slots_data: Array = []
	for slot in ability_slots:
		slots_data.append(slot.to_dict())
	
	return {
		"card_name": card_name,
		"element": element,
		"rarity": rarity,
		"burnable": burnable,
		"slots": slots_data
	}

# Deserialize from saved data (static factory method)
static func from_save_dict(data: Dictionary) -> CardData:
	var card = CardData.new()
	card.card_name = data.get("card_name", "")
	card.element = data.get("element", ElementType.SULFUR)
	card.rarity = data.get("rarity", Rarity.COMMON)
	card.burnable = data.get("burnable", true)  # Default to true for backwards compatibility
	
	var slots_data = data.get("slots", [])
	for slot_data in slots_data:
		var slot = AbilitySlot.new()
		slot.from_dict(slot_data, AbilityRegistry)
		card.ability_slots.append(slot)
	
	return card
