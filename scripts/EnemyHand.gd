extends Node2D

const HAND_COUNT = 10
const CARD_SCENE_PATH = "res://scenes/Card.tscn"
const CARD_WIDTH = 100
const HAND_Y_POSITION = 110  # Top of screen (opposite of player hand at 890)
# Duration for each card to travel (matches card_flip)
const DEAL_ANIMATION_DURATION: float = 0.2
const DEAL_DELAY: float = 0.05  # Delay between dealing each card (twice as fast)

var enemy_hand = []
var center_screen_x
var card_id_counter = 1  # Counter for unique card IDs (starts at 1, goes to 10)
var cards_to_deal = []  # Queue of cards waiting to be dealt
var is_dealing: bool = false  # Track if we're currently dealing

func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	
	# Get deck position and convert to local coordinates relative to CardManager
	var deck = get_parent().get_node_or_null("DeckSlotEnemy")
	var card_manager = $"../CardManager"
	var deck_global_position = Vector2(1511, 113)  # Default enemy deck position
	if deck:
		deck_global_position = deck.global_position
	
	# Convert deck position to local coordinates relative to CardManager
	var _deck_local_position = card_manager.to_local(deck_global_position)
	
	# Store deck position and card manager for later use
	# We'll create cards and draw from deck one at a time during dealing
	# Store these references for use in deal_cards
	cards_to_deal.clear()  # Make sure it's empty
	
	# Check if we're loading a saved match state
	await get_tree().process_frame  # Wait one frame to ensure everything is initialized
	
	# Only auto-deal if there's no saved match state to load
	if SaveManager and SaveManager.current_save_data:
		if SaveManager.current_save_data.has_match_to_resume():
			print("[EnemyHand] Saved match state detected, skipping auto-deal")
			return
	
	# Wait for EnemyDeck to be initialized
	var enemy_deck = get_parent().get_node_or_null("EnemyDeck")
	if enemy_deck:
		# Wait for deck to be initialized (check up to 10 frames)
		for i in range(10):
			await get_tree().process_frame
			var deck_size = 0
			if enemy_deck.has_method("get_deck_size"):
				deck_size = enemy_deck.get_deck_size()
			elif "deck" in enemy_deck:
				deck_size = enemy_deck.deck.size()
			
			if deck_size > 0:
				print("[EnemyHand] EnemyDeck is ready with ", deck_size, " cards")
				break
			elif i == 9:
				print("[EnemyHand] WARNING: EnemyDeck still not ready after 10 frames!")
	
	# Start dealing cards automatically
	deal_cards()

# Update hand size display in GameState
func _update_hand_size_display() -> void:
	var game_state = get_parent().get_node_or_null("GameState")
	if game_state and game_state.has_method("update_hand_size_display"):
		game_state.update_hand_size_display()
		
func add_card_to_hand(card):
	enemy_hand.insert(0, card)
	update_hand_positions()

# Deal cards from deck to hand one at a time
func deal_cards() -> void:
	if is_dealing:
		return
	
	is_dealing = true
	
	# Get references needed for dealing
	var deck = get_parent().get_node_or_null("DeckSlotEnemy")
	var card_manager = $"../CardManager"
	var enemy_deck = get_parent().get_node_or_null("EnemyDeck")
	
	if not enemy_deck:
		print("[EnemyHand] ERROR: EnemyDeck node not found!")
		is_dealing = false
		return
	
	var deck_global_position = Vector2(1511, 113)  # Default enemy deck position
	if deck:
		deck_global_position = deck.global_position
	
	# Convert deck position to local coordinates relative to CardManager
	var deck_local_position = card_manager.to_local(deck_global_position)
	var card_scene = preload(CARD_SCENE_PATH)
	
	# Check if deck is initialized and has cards
	if not enemy_deck or not enemy_deck.has_method("draw_card"):
		print("[EnemyHand] ERROR: EnemyDeck not found or invalid!")
		is_dealing = false
		return
	
	# Wait a frame to ensure deck is fully initialized
	await get_tree().process_frame
	
	# Check deck size
	var deck_size = 0
	if enemy_deck.has_method("get_deck_size"):
		deck_size = enemy_deck.get_deck_size()
	else:
		deck_size = enemy_deck.deck.size() if "deck" in enemy_deck else 0
	
	if deck_size == 0:
		print("[EnemyHand] ERROR: EnemyDeck is empty! Cannot deal cards.")
		is_dealing = false
		return
	
	print("[EnemyHand] Starting to deal cards. Deck size: ", deck_size)
	
	# Deal each card one at a time, drawing from deck as we go
	for i in range(HAND_COUNT):
		# Check if deck still has cards
		if enemy_deck.has_method("get_deck_size"):
			deck_size = enemy_deck.get_deck_size()
		else:
			deck_size = enemy_deck.deck.size() if "deck" in enemy_deck else 0
		
		if deck_size == 0:
			print("[EnemyHand] WARNING: Deck ran out of cards while dealing (dealt ", i, " cards)")
			break
		
		# Draw a card from the deck NOW (this will decrease the deck counter)
		var card_data = enemy_deck.draw_card()
		if not card_data:
			print("[EnemyHand] WARNING: Could not draw card ", i + 1, " - deck may be empty")
			break
		
		# Instantiate the card
		var new_card = card_scene.instantiate()
		
		# Set card number based on when it's dealt (static, never changes)
		var card_number = card_id_counter
		card_id_counter += 1
		
		# Give each card a unique name based on its card number for debug
		new_card.name = "EnemyCard" + str(card_number)
		
		# Set the card number immediately (this is static and won't change)
		if new_card.has_method("set_card_number"):
			new_card.set_card_number(card_number)
		# Also store in meta for reference
		new_card.set_meta("card_number", card_number)
		new_card.set_meta("is_enemy_card", true)  # Mark as enemy card
		
		# Position card at deck location BEFORE adding to tree (prevents flash at origin)
		new_card.position = deck_local_position
		
		# Add card to card_manager
		card_manager.add_child(new_card)
		
		# Wait a frame to ensure card is fully in tree before setting data
		await get_tree().process_frame
		
		# Verify card is at deck position (in case something moved it)
		new_card.position = deck_local_position
		
		# Set the card data (which will update the display)
		if card_data:
			if new_card.has_method("set_card_data"):
				new_card.set_card_data(card_data)
				# Force an immediate update as well
				if new_card.has_method("update_card_display"):
					new_card.update_card_display()
		
		# Register card with CardManager for dragging
		if card_manager:
			card_manager.register_card(new_card)
		
		# Insert card at the beginning of the hand array (position 0)
		enemy_hand.insert(0, new_card)
		
		# Update positions for all cards in hand (they may shift as hand grows)
		# This ensures the hand stays centered as cards are added
		for j in range(enemy_hand.size()):
			var card_in_hand = enemy_hand[j]
			var new_position = Vector2(calculate_card_position(j), HAND_Y_POSITION)
			
			if card_in_hand == new_card:
				# This is the newly dealt card - animate from deck to position 0
				card_in_hand.set_meta("starting_position", new_position)
				await _deal_single_card(card_in_hand, new_position)
			else:
				# Existing card - smoothly update position if it changed
				var current_pos = card_in_hand.position
				# Only animate if moved significantly
				var distance = current_pos.distance_to(new_position)
				if distance > 1.0:
					card_in_hand.set_meta("starting_position", new_position)
					animate_card_to_position(card_in_hand, new_position)
			
			# Update z-index for all cards
			var hand_size = enemy_hand.size()
			var z_index_value = (hand_size - j) * 10
			card_in_hand.z_index = z_index_value
		
		# Small delay before dealing next card
		await get_tree().create_timer(DEAL_DELAY).timeout
	
	is_dealing = false
	print("[EnemyHand] Finished dealing all cards")

# Animate a single card from deck to hand position
func _deal_single_card(card: Node2D, target_position: Vector2) -> void:
	if not card or not is_instance_valid(card):
		return
	
	# Ensure card starts at deck position (in case it was moved)
	var deck = get_parent().get_node_or_null("DeckSlotEnemy")
	var card_manager = $"../CardManager"
	if deck and card_manager:
		var deck_global_position = deck.global_position
		var deck_local_position = card_manager.to_local(deck_global_position)
		card.position = deck_local_position
	
	# Play the card flip animation if available
	var animation_player = card.get_node_or_null("AnimationPlayer")
	if animation_player:
		if animation_player.has_animation("card_flip"):
			animation_player.play("card_flip")
		else:
			print("[EnemyHand] WARNING: card_flip animation not found in AnimationPlayer")
	
	# Create tween for smooth animation
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate to target position
	tween.tween_property(card, "position", target_position, DEAL_ANIMATION_DURATION)
	
	# Wait for animation to complete
	await tween.finished

# Add a card to the hand at a specific index
func add_card_to_hand_at_index(card, target_index: int):
	if card in enemy_hand:
		# Card already in hand, just reorder
		reorder_card_in_hand(card, target_index)
		return
	
	# Add card to hand at target index
	target_index = clamp(target_index, 0, enemy_hand.size())
	enemy_hand.insert(target_index, card)
	update_hand_positions()
	print(
		"[EnemyHand] Added card to hand at index: ",
		target_index,
		" | Hand size: ",
		enemy_hand.size()
	)

# Check if a position is within the hand area
func is_position_in_hand_area(position: Vector2) -> bool:
	if enemy_hand.is_empty():
		return false
	
	var hand_start_x = calculate_card_position(0) - CARD_WIDTH / 2
	var hand_end_x = calculate_card_position(enemy_hand.size() - 1) + CARD_WIDTH / 2
	var hand_top_y = HAND_Y_POSITION - 110  # Half card height above center
	var hand_bottom_y = HAND_Y_POSITION + 110  # Half card height below center
	
	return (
		position.x >= hand_start_x and
		position.x <= hand_end_x and
		position.y >= hand_top_y and
		position.y <= hand_bottom_y
	)

# Check if a card overlaps with the hand area (any part of card touching hand)
func does_card_overlap_hand_area(card: Node2D) -> bool:
	if enemy_hand.is_empty() or not card:
		return false
	
	# Card dimensions (from Card.tscn)
	const CARD_WIDTH: float = 148.0
	const CARD_HEIGHT: float = 209.0
	
	# Get card's bounding box in global coordinates
	var card_global_pos = card.global_position
	var card_left = card_global_pos.x - CARD_WIDTH / 2
	var card_right = card_global_pos.x + CARD_WIDTH / 2
	var card_top = card_global_pos.y - CARD_HEIGHT / 2
	var card_bottom = card_global_pos.y + CARD_HEIGHT / 2
	
	# Get hand area bounds
	var hand_start_x = calculate_card_position(0) - CARD_WIDTH / 2
	var hand_end_x = calculate_card_position(enemy_hand.size() - 1) + CARD_WIDTH / 2
	var hand_top_y = HAND_Y_POSITION - CARD_HEIGHT / 2
	var hand_bottom_y = HAND_Y_POSITION + CARD_HEIGHT / 2
	
	# Check if card's bounding box overlaps with hand area
	var overlaps_horizontally = card_right >= hand_start_x and card_left <= hand_end_x
	var overlaps_vertically = card_bottom >= hand_top_y and card_top <= hand_bottom_y
	
	return overlaps_horizontally and overlaps_vertically
		
func update_hand_positions():
	# Get InputManager to check if cards are being dragged
	var input_manager = get_parent().get_node_or_null("InputManager")
	var is_dragging_any = false
	var dragged_card_ref = null
	if input_manager and input_manager.has_method("get_dragged_card"):
		dragged_card_ref = input_manager.get_dragged_card()
		if "is_dragging" in input_manager:
			is_dragging_any = input_manager.is_dragging
	
	for i in range(enemy_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = enemy_hand[i]
		# Store starting position as meta data (proper way to attach data to nodes)
		card.set_meta("starting_position", new_position)
		
		# Card numbers are static (set when dealt) - don't update them here
		
		# Set z-index: leftmost card (index 0) is on top (highest z-index)
		# Rightmost card is on bottom (lowest z-index)
		# Use larger spacing to ensure proper layering
		# BUT: Don't modify z_index if this card is currently being dragged
		if not is_dragging_any or card != dragged_card_ref:
			var z_index_value = (enemy_hand.size() - i) * 10
			card.z_index = z_index_value
		
		animate_card_to_position(card, new_position)
		
func calculate_card_position(index):
	var total_width = (enemy_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset

func animate_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.1)

# Check if a card is in the enemy's hand
func is_card_in_hand(card) -> bool:
	return card in enemy_hand

# Get a card's index in the hand
func get_card_index(card) -> int:
	if card in enemy_hand:
		return enemy_hand.find(card)
	return -1

# Update a single card's z_index based on its position in hand
func update_card_z_index(card) -> void:
	if not card in enemy_hand:
		return
	
	# Don't modify z_index if this card is currently being dragged
	var input_manager = get_parent().get_node_or_null("InputManager")
	if input_manager and input_manager.has_method("get_dragged_card"):
		var is_dragging = false
		if "is_dragging" in input_manager:
			is_dragging = input_manager.is_dragging
		var dragged_card_ref = input_manager.get_dragged_card()
		if is_dragging and card == dragged_card_ref:
			return  # Don't modify z_index of dragged card
	
	var card_index = enemy_hand.find(card)
	if card_index == -1:
		return
	
	# Calculate correct z_index based on position (same logic as update_hand_positions)
	var hand_size = enemy_hand.size()
	var z_index_value = (hand_size - card_index) * 10
	card.z_index = z_index_value

# Calculate target index in hand from X position
func calculate_index_from_x(x_pos: float) -> int:
	var hand_size = enemy_hand.size()
	if hand_size == 0:
		return 0
	
	# Calculate the relative position (0.0 to 1.0) within the hand area
	var hand_start_x = calculate_card_position(0)
	var hand_end_x = calculate_card_position(hand_size - 1)
	var hand_width = hand_end_x - hand_start_x
	
	if hand_width <= 0:
		return 0
	
	var relative_pos = (x_pos - hand_start_x) / hand_width
	relative_pos = clamp(relative_pos, 0.0, 1.0)
	
	# Convert to index
	var target_index = int(round(relative_pos * (hand_size - 1)))
	return clamp(target_index, 0, hand_size - 1)

# Reorder a card in the hand to a new index
func reorder_card_in_hand(card, target_index: int):
	if not card in enemy_hand:
		return
	
	var current_index = enemy_hand.find(card)
	if current_index == -1:
		return
	
	# Clamp target index to valid range
	target_index = clamp(target_index, 0, enemy_hand.size() - 1)
	
	# If already at target, just update positions
	if current_index == target_index:
		update_hand_positions()
		return
	
	# Remove from current position
	enemy_hand.erase(card)
	
	# Insert at new position
	enemy_hand.insert(target_index, card)
	
	# Update all positions and z-indices immediately
	# This will set correct z-index for all cards including the reordered one
	update_hand_positions()
	
	print(
		"[EnemyHand] Reordered card: ",
		card.name,
		" from index ",
		current_index,
		" to ",
		target_index
	)

# Remove a card from the hand and update positions to close the gap
func remove_card_from_hand(card):
	if card in enemy_hand:
		enemy_hand.erase(card)
		update_hand_positions()
		print(
		"[EnemyHand] Removed card from hand: ",
		card.name,
		" | Hand size: ",
		enemy_hand.size()
	)
	_update_hand_size_display()
