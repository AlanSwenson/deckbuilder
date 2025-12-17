extends Node2D

# Module references
var ai_card_player: AICardPlayer = null
var damage_calculator: DamageCalculator = null
var card_discarder: CardDiscarder = null
var hand_refiller: HandRefiller = null

# References
var card_manager: Node2D = null
var enemy_deck: Node2D = null
var player_deck: Node2D = null
var player_hand: Node2D = null
var enemy_hand: Node2D = null
var game_state: Node2D = null
var is_refilling_hands: bool = false  # Track if hands are currently being refilled

func _ready() -> void:
	# Find references
	card_manager = get_parent().get_node_or_null("CardManager")
	enemy_deck = get_parent().get_node_or_null("EnemyDeck")
	player_deck = get_parent().get_node_or_null("PlayerDeck")
	player_hand = get_parent().get_node_or_null("PlayerHand")
	enemy_hand = get_parent().get_node_or_null("EnemyHand")
	game_state = get_parent().get_node_or_null("GameState")
	
	if not card_manager:
		print("[TurnLogic] ERROR: CardManager not found")
	if not enemy_deck:
		print("[TurnLogic] ERROR: EnemyDeck not found")
	if not player_deck:
		print("[TurnLogic] ERROR: PlayerDeck not found")
	if not player_hand:
		print("[TurnLogic] ERROR: PlayerHand not found")
	if not enemy_hand:
		print("[TurnLogic] ERROR: EnemyHand not found")
	
	# Initialize modules
	ai_card_player = AICardPlayer.new()
	add_child(ai_card_player)
	ai_card_player.setup(enemy_hand, card_manager, game_state, self)
	
	damage_calculator = DamageCalculator.new()
	add_child(damage_calculator)
	var turn_history = get_parent().get_node_or_null("TurnHistory")
	damage_calculator.setup(
		game_state, 
		turn_history, 
		player_hand, 
		player_deck, 
		enemy_hand, 
		enemy_deck, 
		card_manager
	)
	
	card_discarder = CardDiscarder.new()
	add_child(card_discarder)
	card_discarder.setup(player_deck, enemy_deck, game_state)
	
	hand_refiller = HandRefiller.new()
	add_child(hand_refiller)
	hand_refiller.setup(player_hand, enemy_hand, player_deck, enemy_deck, card_manager, game_state)
	
	# Discard selection is now handled directly in PlayerHand - no separate UI needed
	
	# Connect to Play Hand button
	var play_hand_button = get_parent().get_node_or_null("PlayHandButton")
	if play_hand_button:
		play_hand_button.pressed.connect(_on_play_hand_pressed)
		print("[TurnLogic] Connected to PlayHandButton")
	else:
		print("[TurnLogic] WARNING: PlayHandButton not found")

func _on_play_hand_pressed() -> void:
	print("[TurnLogic] ===== Play Hand button pressed - evaluating turn =====")
	
	# Check if hand size exceeds max hand size
	if player_hand and "player_hand" in player_hand:
		var current_hand_size = player_hand.player_hand.size()
		var max_hand_size = 10  # Default max hand size
		if game_state and "player_max_hand_size" in game_state:
			max_hand_size = game_state.player_max_hand_size
		
		if current_hand_size > max_hand_size:
			var cards_needed = current_hand_size - max_hand_size
			print("[TurnLogic] Hand size (%d) exceeds max (%d), entering discard mode (need to discard %d)" % [current_hand_size, max_hand_size, cards_needed])
			if player_hand.has_method("enter_discard_mode"):
				player_hand.enter_discard_mode(cards_needed, _on_discard_complete)
				return  # Wait for discard selection
			else:
				push_error("[TurnLogic] PlayerHand doesn't have enter_discard_mode method!")
	
	# Proceed with turn evaluation
	evaluate_turn()

func _on_discard_complete() -> void:
	print("[TurnLogic] ===== Discard complete callback called - proceeding with turn evaluation =====")
	evaluate_turn()

func evaluate_turn() -> void:
	# Check if game is still playing before starting turn
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game is over, cannot evaluate turn")
			return
	
	# Clear turn history at the start of each turn
	var turn_history = get_parent().get_node_or_null("TurnHistory")
	if turn_history and turn_history.has_method("clear_history"):
		turn_history.clear_history()
	
	# First, determine AI cards to play and place them in enemy slots
	# Make sure we wait for play_ai_cards to complete (including any wait for hand refill)
	await ai_card_player.play_ai_cards()
	
	# Check again after playing AI cards (in case game ended)
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game ended during AI card play, stopping turn")
			return
	
	# Wait a moment for AI cards to be placed
	await get_tree().create_timer(0.5).timeout
	
	# Check again after waiting (in case game ended during wait)
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game ended during wait, stopping turn")
			return
	
	# Resolve turn - calculate damage and apply it
	_resolve_turn()
	
	# Check again after resolving turn (in case HP reached 0)
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game ended during turn resolution, skipping cleanup")
			return
	
	# Clean up and prepare for next turn (but DON'T play enemy cards - that happens at the START of next turn)
	_cleanup_turn()

# Resolve the turn - slot by slot resolution
func _resolve_turn() -> void:
	print("[TurnLogic] Resolving turn slot by slot...")
	
	# Check if game is still playing
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game is over, skipping turn resolution")
			return
	
	# Resolve slot by slot (1-5)
	await damage_calculator.resolve_turn_slot_by_slot()

# Clean up after turn resolution
func _cleanup_turn() -> void:
	# Check if game is over before continuing
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game is over, skipping cleanup")
			return
	
	print("[TurnLogic] Cleaning up turn...")
	
	# Move all cards from player slots to discard
	await card_discarder.discard_player_slot_cards()
	
	# Check if game ended during discard
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game ended during discard, stopping cleanup")
			return
	
	# Clear enemy slots (for now, just remove the cards)
	await card_discarder.clear_enemy_slots()
	
	# Check if game ended during enemy slot clearing
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game ended during enemy slot clearing, stopping cleanup")
			return
	
	# Refill player hand to original amount (only if game is still playing)
	# NOTE: We refill hands but do NOT play enemy cards - that only happens when "Play Hand" is pressed
	if game_state and game_state.has_method("is_game_playing"):
		if game_state.is_game_playing():
			is_refilling_hands = true
			print("[TurnLogic] ===== Starting hand refill - setting is_refilling_hands=true =====")
			await hand_refiller.refill_player_hand()
			print("[TurnLogic] Player hand refill complete, is_refilling_hands=", is_refilling_hands)
			
			# Check again after refilling player hand
			if game_state and game_state.has_method("is_game_playing"):
				if game_state.is_game_playing():
					print("[TurnLogic] Starting enemy hand refill, is_refilling_hands=", is_refilling_hands)
					await hand_refiller.refill_enemy_hand()
					print("[TurnLogic] Enemy hand refill complete, is_refilling_hands=", is_refilling_hands)
					print("[TurnLogic] Hands refilled. Enemy will play cards when 'Play Hand' is pressed next.")
				else:
					print("[TurnLogic] Game ended during player hand refill, stopping enemy hand refill")
			else:
				print("[TurnLogic] Game ended during player hand refill, stopping enemy hand refill")
			
			# Always clear the flag when refill is done (whether successful or not)
			is_refilling_hands = false
			print("[TurnLogic] Hand refill complete - setting is_refilling_hands=false")
			
			# Autosave game state after turn cleanup
			if SaveManager:
				SaveManager.autosave_game_state()
		else:
			print("[TurnLogic] Game is over, skipping hand refill")
			is_refilling_hands = false
	else:
		print("[TurnLogic] Game is over, skipping hand refill")
		is_refilling_hands = false
