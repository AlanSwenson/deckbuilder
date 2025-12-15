extends Node2D

# Player's deck of 30 cards
var deck: Array[CardData] = []
var discard_pile: Array[CardData] = []
var original_deck: Array[CardData] = []  # Store the original full deck

func _ready() -> void:
	# Load deck from save data
	initialize_deck()

# Initialize the deck from save data (or create new if no save)
func initialize_deck() -> void:
	# Check if SaveManager has a current save with a deck
	if SaveManager and SaveManager.current_save_data:
		var save_data = SaveManager.current_save_data
		print("[PlayerDeck] Save data found - deck size in save: %d" % save_data.current_deck.size())
		
		# Load deck from save if it exists
		if not save_data.current_deck.is_empty():
			deck = save_data.get_current_deck()
			print("[PlayerDeck] Loaded deck from save with %d cards" % deck.size())
			if deck.size() > 0:
				print("[PlayerDeck] First card: %s (rarity: %d, damage: %d)" % [deck[0].card_name, deck[0].rarity, deck[0].get_total_damage()])
		else:
			# Fallback: create starter collection if save has no deck (shouldn't happen, but safety)
			print("[PlayerDeck] WARNING: Save has no deck, creating starter collection")
			var starter_collection = ExampleCards.create_starter_collection()
			for card in starter_collection:
				save_data.add_card_to_collection(card)
			# Use first 30 cards as default deck
			deck = starter_collection.slice(0, mini(30, starter_collection.size()))
			save_data.set_current_deck(deck)
			SaveManager.save_game()
	else:
		# No save loaded - create starter collection (shouldn't happen in normal flow)
		print("[PlayerDeck] WARNING: No save data found, creating starter collection")
		var starter_collection = ExampleCards.create_starter_collection()
		deck = starter_collection.slice(0, mini(30, starter_collection.size()))
	
	# Store a copy of the original deck for reference
	original_deck = []
	for card in deck:
		original_deck.append(card.create_instance())
	
	# Shuffle the deck
	shuffle_deck()
	print("[PlayerDeck] Initialized deck with %d cards" % deck.size())

# Shuffle the deck randomly
func shuffle_deck() -> void:
	deck.shuffle()
	print("[PlayerDeck] Deck shuffled")

# Draw a random card from the deck
func draw_card() -> CardData:
	# Check lose condition: if deck is empty, player loses
	if deck.is_empty():
		print("[PlayerDeck] Deck is empty! Player loses!")
		var game_state = get_parent().get_node_or_null("GameState")
		if not game_state:
			var scene_root = get_tree().current_scene
			if scene_root:
				game_state = scene_root.get_node_or_null("GameState")
		if game_state and game_state.has_method("is_game_playing"):
			if game_state.is_game_playing() and game_state.has_method("lose_game"):
				game_state.lose_game()
		return null
	
	var drawn_card = deck.pop_back()
	print("[PlayerDeck] Drew card: ", drawn_card.card_name, " | Deck size: ", deck.size())
	return drawn_card

# Add a card to the discard pile
func discard_card(card_data: CardData) -> void:
	if card_data:
		# Duplicate the card data so each card instance is tracked separately
		# This prevents cards with the same name from being treated as the same card
		var duplicated_card = card_data.duplicate(true)
		discard_pile.append(duplicated_card)

# Get the number of cards remaining in deck
func get_deck_size() -> int:
	return deck.size()

# Get the number of cards in discard pile
func get_discard_size() -> int:
	return discard_pile.size()

# Save the current deck state to save data
# Useful when player modifies their deck between runs
func save_deck_to_save() -> void:
	if SaveManager and SaveManager.current_save_data:
		# Save the original deck (before shuffling/drawing)
		SaveManager.current_save_data.set_current_deck(original_deck)
		SaveManager.save_game()
		print("[PlayerDeck] Saved deck to save data")
	else:
		push_warning("[PlayerDeck] Cannot save deck - no save data available")

# Reset deck to original state (for starting a new run)
func reset_deck() -> void:
	deck.clear()
	discard_pile.clear()
	
	# Restore from original deck
	for card in original_deck:
		deck.append(card.create_instance())
	
	shuffle_deck()
	print("[PlayerDeck] Reset deck to original state with ", deck.size(), " cards")
