extends Node2D

# Player's deck of 30 cards
var deck: Array[CardData] = []
var discard_pile: Array[CardData] = []
var original_deck: Array[CardData] = []  # Store the original full deck

func _ready() -> void:
	# Initialize the deck with 30 cards from example_cards
	initialize_deck()

# Initialize the deck with 30 cards
func initialize_deck() -> void:
	# Get the starter deck from ExampleCards
	deck = ExampleCards.create_starter_deck()
	# Store a copy of the original deck
	original_deck = deck.duplicate(true)
	# Shuffle the deck
	shuffle_deck()
	print("[PlayerDeck] Initialized deck with ", deck.size(), " cards")

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
