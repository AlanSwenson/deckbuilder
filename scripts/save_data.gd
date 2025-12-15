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

# Multiple named decks - allows players to create and switch between decks
# Format: {"Deck Name": Array[Dictionary], ...}
@export var decks: Dictionary = {}  # Dictionary of deck_name -> Array[Dictionary]
@export var current_deck_name: String = "Default Deck"  # Name of the currently active deck

# Add more data as needed
@export var ingredients: Dictionary = {}
@export var recipes_unlocked: Array[String] = []

# In-progress match state (for autosave/crash recovery)
@export var has_active_match: bool = false
@export var match_player_hp: int = 100
@export var match_enemy_hp: int = 100
@export var match_game_status: int = 0  # GameState.GameStatus enum value
@export var match_player_hand: Array[Dictionary] = []  # Cards in player hand
@export var match_enemy_hand: Array[Dictionary] = []  # Cards in enemy hand
@export var match_player_deck: Array[Dictionary] = []  # Remaining player deck
@export var match_enemy_deck: Array[Dictionary] = []  # Remaining enemy deck
@export var match_player_discard: Array[Dictionary] = []  # Player discard pile
@export var match_enemy_discard: Array[Dictionary] = []  # Enemy discard pile
@export var match_player_slots: Array[Dictionary] = []  # Cards in PlayerSlot1-5
@export var match_enemy_slots: Array[Dictionary] = []  # Cards in EnemySlot1-5
@export var match_turn_number: int = 0  # Current turn number

func _init():
	pass

# Check if this save slot has data
func is_empty() -> bool:
	# A save is empty if it has no runs AND no collection
	# This allows new saves with collections to be considered "not empty"
	return total_runs == 0 and card_collection.is_empty()

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
		
		# Show collection size (total cards owned)
		var collection_size = card_collection.size()
		
		# Check if there's an in-progress match
		var match_status = ""
		if has_active_match:
			match_status = " [IN PROGRESS]"
		
		# Format: Name on first line, stats on second line, time on third
		return "%s%s\n%d Runs • Act %d • %d Cards\nPlay Time: %s" % [display_name, match_status, total_runs, current_act, collection_size, time_str]

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

# ============================================
# MATCH STATE SAVE/LOAD (Autosave)
# ============================================

# Clear match state (when starting a new match)
func clear_match_state() -> void:
	has_active_match = false
	match_player_hp = 100
	match_enemy_hp = 100
	match_game_status = 0
	match_player_hand.clear()
	match_enemy_hand.clear()
	match_player_deck.clear()
	match_enemy_deck.clear()
	match_player_discard.clear()
	match_enemy_discard.clear()
	match_player_slots.clear()
	match_enemy_slots.clear()
	match_turn_number = 0

# Check if there's an active match to resume
func has_match_to_resume() -> bool:
	return has_active_match and (not match_player_hand.is_empty() or not match_player_deck.is_empty())

# ============================================
# DECK MANAGEMENT
# ============================================

# Create a new deck from the collection
func create_deck(deck_name: String, card_indices: Array[int]) -> bool:
	if deck_name == "":
		return false
	
	var deck_cards: Array[Dictionary] = []
	for idx in card_indices:
		if idx >= 0 and idx < card_collection.size():
			deck_cards.append(card_collection[idx])
	
	decks[deck_name] = deck_cards
	return true

# Get a deck by name
func get_deck(deck_name: String) -> Array[CardData]:
	if deck_name in decks:
		var cards: Array[CardData] = []
		for card_dict in decks[deck_name]:
			cards.append(CardData.from_save_dict(card_dict))
		return cards
	return []

# Delete a deck
func delete_deck(deck_name: String) -> bool:
	if deck_name in decks:
		decks.erase(deck_name)
		# If we deleted the current deck, switch to default
		if current_deck_name == deck_name:
			if decks.has("Default Deck"):
				current_deck_name = "Default Deck"
				current_deck = decks["Default Deck"]
			else:
				current_deck_name = ""
				current_deck.clear()
		return true
	return false

# Set the current active deck
func set_active_deck(deck_name: String) -> bool:
	if deck_name in decks:
		current_deck_name = deck_name
		current_deck = decks[deck_name]
		return true
	return false

# ============================================
# CARD BURNING (Destroying cards)
# ============================================

# Burn (destroy) a card from the collection
# Only works if the card is burnable
func burn_card(card_index: int) -> bool:
	if card_index < 0 or card_index >= card_collection.size():
		return false
	
	var card_dict = card_collection[card_index]
	var card = CardData.from_save_dict(card_dict)
	
	# Check if card is burnable
	if not card.burnable:
		print("[SaveData] Card %s is not burnable" % card.card_name)
		return false
	
	# Remove from collection
	card_collection.remove_at(card_index)
	cards_collected = card_collection.size()
	
	# Remove from all decks that contain this card
	for deck_name in decks.keys():
		var deck = decks[deck_name]
		var i = 0
		while i < deck.size():
			# Compare by card data (name, element, rarity, and ability values)
			if _cards_match(deck[i], card_dict):
				deck.remove_at(i)
			else:
				i += 1
	
	# Also remove from current_deck if it matches
	var i = 0
	while i < current_deck.size():
		if _cards_match(current_deck[i], card_dict):
			current_deck.remove_at(i)
		else:
			i += 1
	
	print("[SaveData] Burned card: %s" % card.card_name)
	return true

# Helper to check if two card dictionaries match (same card instance)
func _cards_match(card1: Dictionary, card2: Dictionary) -> bool:
	# For now, match by name, element, rarity, and ability values
	# This is a simple approach - you might want more sophisticated matching
	if card1.get("card_name") != card2.get("card_name"):
		return false
	if card1.get("element") != card2.get("element"):
		return false
	if card1.get("rarity") != card2.get("rarity"):
		return false
	
	# Compare ability slots
	var slots1 = card1.get("slots", [])
	var slots2 = card2.get("slots", [])
	if slots1.size() != slots2.size():
		return false
	
	for i in range(slots1.size()):
		var slot1 = slots1[i]
		var slot2 = slots2[i]
		if slot1.get("ability_id") != slot2.get("ability_id"):
			return false
		if slot1.get("rolled_value") != slot2.get("rolled_value"):
			return false
	
	return true
