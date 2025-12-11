extends Node2D

const HAND_COUNT = 10
const CARD_SCENE_PATH = "res://scenes/Card.tscn"
const CARD_WIDTH = 100
const HAND_Y_POSITION = 890

var player_hand = []
var center_screen_x
var card_id_counter = 0  # Counter for unique card IDs

func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	
	var card_manager = $"../CardManager"
	var card_scene = preload(CARD_SCENE_PATH)
	for i in range(HAND_COUNT):
		var new_card = card_scene.instantiate()
		card_manager.add_child(new_card)
		new_card.name = "Card" + str(i)  # Give each card a unique name
		# Set a unique card number for testing/identification (never changes)
		if new_card.has_method("set_card_number"):
			new_card.set_card_number(card_id_counter)
		card_id_counter += 1
		# Ensure the card is registered with CardManager for dragging
		card_manager.register_card(new_card)
		add_card_to_hand(new_card)
		
func add_card_to_hand(card):
	player_hand.insert(0, card)
	update_hand_positions()

# Add a card to the hand at a specific index
func add_card_to_hand_at_index(card, target_index: int):
	if card in player_hand:
		# Card already in hand, just reorder
		reorder_card_in_hand(card, target_index)
		return
	
	# Add card to hand at target index
	target_index = clamp(target_index, 0, player_hand.size())
	player_hand.insert(target_index, card)
	update_hand_positions()
	print(
		"[PlayerHand] Added card to hand at index: ",
		target_index,
		" | Hand size: ",
		player_hand.size()
	)

# Check if a position is within the hand area
func is_position_in_hand_area(position: Vector2) -> bool:
	if player_hand.is_empty():
		return false
	
	var hand_start_x = calculate_card_position(0) - CARD_WIDTH / 2
	var hand_end_x = calculate_card_position(player_hand.size() - 1) + CARD_WIDTH / 2
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
	if player_hand.is_empty() or not card:
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
	var hand_end_x = calculate_card_position(player_hand.size() - 1) + CARD_WIDTH / 2
	var hand_top_y = HAND_Y_POSITION - CARD_HEIGHT / 2
	var hand_bottom_y = HAND_Y_POSITION + CARD_HEIGHT / 2
	
	# Check if card's bounding box overlaps with hand area
	var overlaps_horizontally = card_right >= hand_start_x and card_left <= hand_end_x
	var overlaps_vertically = card_bottom >= hand_top_y and card_top <= hand_bottom_y
	
	return overlaps_horizontally and overlaps_vertically
		
func update_hand_positions():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		# Store starting position as meta data (proper way to attach data to nodes)
		card.set_meta("starting_position", new_position)
		# Set z-index: leftmost card (index 0) is on top (highest z-index)
		# Rightmost card is on bottom (lowest z-index)
		# Use larger spacing to ensure proper layering
		var z_index_value = (player_hand.size() - i) * 10
		card.z_index = z_index_value
		# Note: Card numbers are NOT updated here - they stay constant for identification
		animate_card_to_position(card, new_position)
		
func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset

func animate_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.1)

# Check if a card is in the player's hand
func is_card_in_hand(card) -> bool:
	return card in player_hand

# Calculate target index in hand from X position
func calculate_index_from_x(x_pos: float) -> int:
	var hand_size = player_hand.size()
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
	if not card in player_hand:
		return
	
	var current_index = player_hand.find(card)
	if current_index == -1:
		return
	
	# Clamp target index to valid range
	target_index = clamp(target_index, 0, player_hand.size() - 1)
	
	# If already at target, just update positions
	if current_index == target_index:
		update_hand_positions()
		return
	
	# Remove from current position
	player_hand.erase(card)
	
	# Insert at new position
	player_hand.insert(target_index, card)
	
	# Update all positions and z-indices immediately
	# This will set correct z-index for all cards including the reordered one
	update_hand_positions()
	
	print(
		"[PlayerHand] Reordered card: ",
		card.name,
		" from index ",
		current_index,
		" to ",
		target_index
	)

# Remove a card from the hand and update positions to close the gap
func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions()
		print(
		"[PlayerHand] Removed card from hand: ",
		card.name,
		" | Hand size: ",
		player_hand.size()
	)
