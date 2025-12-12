extends Node2D

# Enemy's deck
var deck: Array[CardData] = []
var discard_pile: Array[CardData] = []
var original_deck: Array[CardData] = []  # Store the original full deck

func _ready() -> void:
	# Initialize the deck with enemy cards from example_cards
	initialize_deck()

# Initialize the deck with enemy cards
func initialize_deck() -> void:
	# Get the starter enemy deck from ExampleCards
	deck = ExampleCards.create_starter_enemy_deck()
	# Store a copy of the original deck
	original_deck = deck.duplicate(true)
	# Shuffle the deck
	shuffle_deck()
	print("[EnemyDeck] Initialized deck with ", deck.size(), " cards")

# Shuffle the deck randomly
func shuffle_deck() -> void:
	deck.shuffle()
	print("[EnemyDeck] Deck shuffled")

# Draw a random card from the deck
func draw_card() -> CardData:
	print("[EnemyDeck] draw_card() called - Deck size: ", deck.size())
	
	# Check lose condition: if deck is empty, enemy loses (player wins)
	if deck.is_empty():
		print("[EnemyDeck] Deck is empty! Player wins!")
		_trigger_win_condition()
		return null
	
	var drawn_card = deck.pop_back()
	print("[EnemyDeck] Drew card: ", drawn_card.card_name, " | Deck size: ", deck.size())
	return drawn_card

# Add a card to the discard pile
func discard_card(card_data: CardData) -> void:
	if card_data:
		# Duplicate the card data so each card instance is tracked separately
		# This prevents cards with the same name from being treated as the same card
		var duplicated_card = card_data.duplicate(true)
		discard_pile.append(duplicated_card)
		print("[EnemyDeck] Discarded card: ", card_data.card_name, " | Discard pile size: ", discard_pile.size())

# Get the number of cards remaining in deck
func get_deck_size() -> int:
	return deck.size()

# Get the number of cards in discard pile
func get_discard_size() -> int:
	return discard_pile.size()

# Trigger win condition when enemy can't draw
func _trigger_win_condition() -> void:
	print("[EnemyDeck] Enemy deck is empty! Player wins!")
	
	# Try multiple ways to find GameState
	var game_state = get_parent().get_node_or_null("GameState")
	if not game_state:
		# Try getting from scene root
		var scene_root = get_tree().current_scene
		if scene_root:
			game_state = scene_root.get_node_or_null("GameState")
	
	if game_state:
		print("[EnemyDeck] Found GameState node: ", game_state.name)
		# Always check if game is still playing before triggering win
		if game_state.has_method("is_game_playing"):
			var is_playing = game_state.is_game_playing()
			print("[EnemyDeck] Game is playing: ", is_playing)
			if is_playing:
				if game_state.has_method("win_game"):
					print("[EnemyDeck] Calling win_game()...")
					game_state.win_game()
					print("[EnemyDeck] win_game() called successfully")
				else:
					print("[EnemyDeck] ERROR: GameState has no win_game() method")
			else:
				print("[EnemyDeck] Game is already over, not triggering win")
		else:
			# Fallback if is_game_playing doesn't exist
			print("[EnemyDeck] GameState doesn't have is_game_playing(), using fallback")
			if game_state.has_method("win_game"):
				print("[EnemyDeck] Calling win_game() (fallback)...")
				game_state.win_game()
	else:
		print("[EnemyDeck] ERROR: GameState node not found! Tried parent and scene root")
		print("[EnemyDeck] Parent: ", get_parent())
		if get_parent():
			print("[EnemyDeck] Parent children: ", get_parent().get_children())
