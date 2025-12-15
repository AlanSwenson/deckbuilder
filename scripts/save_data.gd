extends Resource
class_name SaveData

@export var slot_number: int = 0
@export var player_name: String = "New Game"
@export var total_runs: int = 0
@export var cards_collected: int = 0
@export var current_act: int = 1
@export var play_time_seconds: float = 0.0

# Card collection - stores full card data with rolled ability values
# Each entry is a Dictionary from CardData.to_save_dict()
# Format: {"card_name": "...", "element": 0, "rarity": 0, "slots": [...]}
@export var card_collection: Array[Dictionary] = []

# Current deck - the player's active deck for runs
# Same format as card_collection
@export var current_deck: Array[Dictionary] = []

# Add more data as needed
@export var ingredients: Dictionary = {}
@export var recipes_unlocked: Array[String] = []

func _init():
	pass

# Check if this save slot has data
func is_empty() -> bool:
	# A save is empty if it has no runs AND no deck
	# This allows new saves with decks to be considered "not empty"
	return total_runs == 0 and current_deck.is_empty()

# Get display text for save slot button
func get_display_text() -> String:
	if is_empty():
		return "EMPTY SLOT"
	else:
		# Use player name if it's been set, otherwise use a default name
		var display_name = player_name
		if display_name == "New Game" or display_name == "":
			display_name = "Save Slot %d" % slot_number
		
		# Format play time
		var hours = int(play_time_seconds / 3600)
		var minutes = int((play_time_seconds - hours * 3600) / 60)
		var time_str = ""
		if hours > 0:
			time_str = "%dh %dm" % [hours, minutes]
		elif minutes > 0:
			time_str = "%dm" % minutes
		else:
			time_str = "<1m"
		
		# Show deck size (what player is actively using)
		var deck_size = current_deck.size()
		
		# Format: Name on first line, stats on second line, time on third
		return "%s\n%d Runs • Act %d • %d Cards\nPlay Time: %s" % [display_name, total_runs, current_act, deck_size, time_str]

# Add a card to the collection
func add_card_to_collection(card: CardData) -> void:
	card_collection.append(card.to_save_dict())
	cards_collected = card_collection.size()

# Get all cards from collection as CardData instances
func get_collection_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card_dict in card_collection:
		var card = CardData.from_save_dict(card_dict)
		cards.append(card)
	return cards

# Set the current deck from an array of CardData
func set_current_deck(deck: Array[CardData]) -> void:
	current_deck.clear()
	for card in deck:
		current_deck.append(card.to_save_dict())

# Get the current deck as CardData instances
func get_current_deck() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card_dict in current_deck:
		var card = CardData.from_save_dict(card_dict)
		cards.append(card)
	return cards

# Get a summary of the card collection by rarity
func get_collection_summary() -> Dictionary:
	var summary = {
		"common": 0,
		"uncommon": 0,
		"rare": 0,
		"epic": 0,
		"legendary": 0,
		"total": card_collection.size()
	}
	
	for card_dict in card_collection:
		var rarity = card_dict.get("rarity", 0)
		match rarity:
			CardData.Rarity.COMMON:
				summary["common"] += 1
			CardData.Rarity.UNCOMMON:
				summary["uncommon"] += 1
			CardData.Rarity.RARE:
				summary["rare"] += 1
			CardData.Rarity.EPIC:
				summary["epic"] += 1
			CardData.Rarity.LEGENDARY:
				summary["legendary"] += 1
	
	return summary
