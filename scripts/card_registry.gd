extends Node

# Singleton that loads and provides access to all card template resources
# Add to Project Settings -> Autoload as "CardRegistry"

# Dictionary mapping card name -> CardData template
var cards: Dictionary = {}

const CARDS_PATH = "res://assets/cards/"

func _ready() -> void:
	# Wait a frame to ensure AbilityRegistry is loaded first
	await get_tree().process_frame
	_load_all_cards()

# Load all .tres files from the cards directory
func _load_all_cards() -> void:
	cards.clear()
	
	var dir = DirAccess.open(CARDS_PATH)
	if not dir:
		push_warning("CardRegistry: Could not open cards directory at %s" % CARDS_PATH)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = CARDS_PATH + file_name
			var card = load(full_path) as CardData
			if card:
				if card.card_name == "":
					push_warning("CardRegistry: Card in %s has no name set" % file_name)
				elif not card.enabled:
					print("[CardRegistry] Skipping disabled card: %s" % card.card_name)
				else:
					cards[card.card_name] = card
					print("[CardRegistry] Loaded card template: %s" % card.card_name)
			else:
				push_warning("CardRegistry: Failed to load card from %s" % file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("[CardRegistry] Loaded %d card templates" % cards.size())

# Get a card template by name
func get_card_template(card_name: String) -> CardData:
	if card_name in cards:
		return cards[card_name]
	push_warning("CardRegistry: Unknown card name: %s" % card_name)
	return null

# Create a new instance of a card with the specified rarity
# This duplicates the template and rolls new stats
func create_card(card_name: String, rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var template = get_card_template(card_name)
	if not template:
		return null
	
	# Create a new card instance from the template
	var card = CardData.new()
	card.card_name = template.card_name
	card.element = template.element
	card.rarity = rarity
	card.card_art = template.card_art
	
	# Copy ability slots from template
	for slot in template.ability_slots:
		var new_slot = slot.duplicate_slot()
		card.ability_slots.append(new_slot)
	
	# Roll stats based on the new rarity
	card.roll_stats()
	card.description = card.generate_description()
	
	return card

# Create a new instance of a card with minimum values (for starter collection)
# This duplicates the template and sets stats to minimum values
func create_card_with_minimum_values(
	card_name: String, 
	rarity: CardData.Rarity = CardData.Rarity.COMMON
) -> CardData:
	var template = get_card_template(card_name)
	if not template:
		return null
	
	# Create a new card instance from the template
	var card = CardData.new()
	card.card_name = template.card_name
	card.element = template.element
	card.rarity = rarity
	card.card_art = template.card_art
	
	# Copy ability slots from template
	for slot in template.ability_slots:
		var new_slot = slot.duplicate_slot()
		card.ability_slots.append(new_slot)
	
	# Set stats to minimum values based on the new rarity
	card.set_minimum_stats()
	card.description = card.generate_description()
	
	return card

# Check if a card exists
func has_card(card_name: String) -> bool:
	return card_name in cards

# Get all loaded card names
func get_all_card_names() -> Array[String]:
	var names: Array[String] = []
	for key in cards.keys():
		names.append(key)
	return names

# Get all cards of a specific element
func get_cards_by_element(element: CardData.ElementType) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in cards.values():
		if card.element == element:
			result.append(card)
	return result

# Reload all cards (useful for development/hot-reloading)
func reload_cards() -> void:
	print("[CardRegistry] Reloading cards...")
	_load_all_cards()
