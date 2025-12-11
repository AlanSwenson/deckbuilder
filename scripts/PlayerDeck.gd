extends Node2D

# Player's deck of 30 cards
var deck: Array[CardData] = []
var discard_pile: Array[CardData] = []

func _ready() -> void:
	# Initialize the deck with 30 cards from example_cards
	initialize_deck()

# Initialize the deck with 30 cards
func initialize_deck() -> void:
	# Get the starter deck from ExampleCards
	deck = ExampleCards.create_starter_deck()
	# Shuffle the deck
	shuffle_deck()
	print("[PlayerDeck] Initialized deck with ", deck.size(), " cards")

# Shuffle the deck randomly
func shuffle_deck() -> void:
	deck.shuffle()
	print("[PlayerDeck] Deck shuffled")

# Draw a random card from the deck
func draw_card() -> CardData:
	if deck.is_empty():
		reshuffle_from_discard()
		if deck.is_empty():
			print("[PlayerDeck] ERROR: Cannot draw, deck is empty!")
			return null
	
	var drawn_card = deck.pop_back()
	print("[PlayerDeck] Drew card: ", drawn_card.card_name, " | Deck size: ", deck.size())
	return drawn_card

# Reshuffle discard pile back into deck if deck is empty
func reshuffle_from_discard() -> void:
	if discard_pile.is_empty():
		print("[PlayerDeck] Discard pile is empty, cannot reshuffle")
		return
	
	print("[PlayerDeck] Reshuffling ", discard_pile.size(), " cards from discard pile")
	deck = discard_pile.duplicate()
	discard_pile.clear()
	shuffle_deck()

# Add a card to the discard pile
func discard_card(card_data: CardData) -> void:
	if card_data:
		discard_pile.append(card_data)

# Get the number of cards remaining in deck
func get_deck_size() -> int:
	return deck.size()

# Get the number of cards in discard pile
func get_discard_size() -> int:
	return discard_pile.size()
