extends Node2D

const HAND_COUNT = 10
const CARD_SCENE_PATH = "res://scenes/Card.tscn"
const CARD_WIDTH = 100
const HAND_Y_POSITION = 890
# Duration for each card to travel (matches card_flip)
const DEAL_ANIMATION_DURATION: float = 0.2
const DEAL_DELAY: float = 0.05  # Delay between dealing each card (twice as fast)

var player_hand = []
var center_screen_x
var card_id_counter = 1  # Counter for unique card IDs (starts at 1, goes to 10)
var cards_to_deal = []  # Queue of cards waiting to be dealt
var is_dealing: bool = false  # Track if we're currently dealing

# Discard selection mode
var is_discard_mode: bool = false
var cards_to_discard: int = 0
var selected_for_discard: Array = []  # Array of cards selected for discard
var discard_callback: Callable = Callable()  # Callback when discard is complete
var discard_status_label: Label = null  # Label showing discard progress
var last_toggled_card: Node2D = null  # Track last card toggled to prevent double-toggle
var last_toggle_time: int = 0  # Track when last toggle happened (in milliseconds)

# Expose discard mode state for InputManager to check
func get_is_discard_mode() -> bool:
	return is_discard_mode

# Update hand size display in GameState
func _update_hand_size_display() -> void:
	var game_state = get_parent().get_node_or_null("GameState")
	if game_state and game_state.has_method("update_hand_size_display"):
		game_state.update_hand_size_display()

func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	
	# Get deck position and convert to local coordinates relative to CardManager
	var deck = get_parent().get_node_or_null("Deck")
	var card_manager = $"../CardManager"
	var deck_global_position = Vector2(150, 890)  # Default deck position
	if deck:
		deck_global_position = deck.global_position
	
	# Convert deck position to local coordinates relative to CardManager
	var deck_local_position = card_manager.to_local(deck_global_position)
	
	# Store deck position and card manager for later use
	# We'll create cards and draw from deck one at a time during dealing
	# Store these references for use in deal_cards
	cards_to_deal.clear()  # Make sure it's empty
	
	# Check if we're loading a saved match state
	await get_tree().process_frame  # Wait one frame to ensure everything is initialized
	
	# Only auto-deal if there's no saved match state to load
	if SaveManager and SaveManager.current_save_data:
		if SaveManager.current_save_data.has_match_to_resume():
			print("[PlayerHand] Saved match state detected, skipping auto-deal")
			return
	
	# Start dealing cards automatically
	deal_cards()
		
func add_card_to_hand(card):
	player_hand.insert(0, card)
	update_hand_positions()

# Deal cards from deck to hand one at a time
func deal_cards() -> void:
	if is_dealing:
		return
	
	is_dealing = true
	
	# Get references needed for dealing
	var deck = get_parent().get_node_or_null("Deck")
	var card_manager = $"../CardManager"
	var player_deck = get_parent().get_node_or_null("PlayerDeck")
	
	if not player_deck:
		print("[PlayerHand] ERROR: PlayerDeck node not found!")
		is_dealing = false
		return
	
	var deck_global_position = Vector2(150, 890)  # Default deck position
	if deck:
		deck_global_position = deck.global_position
	
	# Convert deck position to local coordinates relative to CardManager
	var deck_local_position = card_manager.to_local(deck_global_position)
	var card_scene = preload(CARD_SCENE_PATH)
	
	# Deal each card one at a time, drawing from deck as we go
	for i in range(HAND_COUNT):
		# Draw a card from the deck NOW (this will decrease the deck counter)
		var card_data = null
		if player_deck and player_deck.has_method("draw_card"):
			card_data = player_deck.draw_card()
		else:
			print("[PlayerHand] WARNING: PlayerDeck not found, creating empty card")
		
		# Instantiate the card
		var new_card = card_scene.instantiate()
		
		# Set card number based on when it's dealt (static, never changes)
		var card_number = card_id_counter
		card_id_counter += 1
		
		# Give each card a unique name based on its card number for debug
		new_card.name = "Card" + str(card_number)
		
		# Set the card number immediately (this is static and won't change)
		if new_card.has_method("set_card_number"):
			new_card.set_card_number(card_number)
		# Also store in meta for reference
		new_card.set_meta("card_number", card_number)
		
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
		player_hand.insert(0, new_card)
		
		# Update positions for all cards in hand (they may shift as hand grows)
		# This ensures the hand stays centered as cards are added
		for j in range(player_hand.size()):
			var card_in_hand = player_hand[j]
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
			var hand_size = player_hand.size()
			var z_index_value = (hand_size - j) * 10
			card_in_hand.z_index = z_index_value
		
		# Small delay before dealing next card
		await get_tree().create_timer(DEAL_DELAY).timeout
	
	is_dealing = false
	print("[PlayerHand] Finished dealing all cards")

# Animate a single card from deck to hand position
func _deal_single_card(card: Node2D, target_position: Vector2) -> void:
	if not card or not is_instance_valid(card):
		return
	
	# Ensure card starts at deck position (in case it was moved)
	var deck = get_parent().get_node_or_null("Deck")
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
			print("[PlayerHand] WARNING: card_flip animation not found in AnimationPlayer")
	
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
	_update_hand_size_display()

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
	# Get InputManager to check if cards are being dragged
	var input_manager = get_parent().get_node_or_null("InputManager")
	var is_dragging_any = false
	var dragged_card_ref = null
	if input_manager and input_manager.has_method("get_dragged_card"):
		dragged_card_ref = input_manager.get_dragged_card()
		if "is_dragging" in input_manager:
			is_dragging_any = input_manager.is_dragging
	
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		# Store starting position as meta data (proper way to attach data to nodes)
		card.set_meta("starting_position", new_position)
		
		# Card numbers are static (set when dealt) - don't update them here
		
		# Set z-index: leftmost card (index 0) is on top (highest z-index)
		# Rightmost card is on bottom (lowest z-index)
		# Use larger spacing to ensure proper layering
		# BUT: Don't modify z_index if this card is currently being dragged
		if not is_dragging_any or card != dragged_card_ref:
			var z_index_value = (player_hand.size() - i) * 10
			card.z_index = z_index_value
		
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

# Get a card's index in the hand
func get_card_index(card) -> int:
	if card in player_hand:
		return player_hand.find(card)
	return -1

# Update a single card's z_index based on its position in hand
func update_card_z_index(card) -> void:
	if not card in player_hand:
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
	
	var card_index = player_hand.find(card)
	if card_index == -1:
		return
	
	# Calculate correct z_index based on position (same logic as update_hand_positions)
	var hand_size = player_hand.size()
	var z_index_value = (hand_size - card_index) * 10
	card.z_index = z_index_value

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
	_update_hand_size_display()

# Enter discard selection mode
func enter_discard_mode(needed: int, callback: Callable) -> void:
	is_discard_mode = true
	cards_to_discard = needed
	selected_for_discard.clear()
	discard_callback = callback
	print("[PlayerHand] Entered discard mode - need to discard %d cards" % needed)
	print("[PlayerHand] Callback set: %s (valid: %s)" % [str(callback), str(callback.is_valid())])
	_create_discard_status_label()
	_update_discard_visuals()
	_update_discard_status_label()

# Exit discard selection mode
func exit_discard_mode() -> void:
	is_discard_mode = false
	cards_to_discard = 0
	selected_for_discard.clear()
	discard_callback = Callable()
	_update_discard_visuals()
	_remove_discard_status_label()
	print("[PlayerHand] Exited discard mode")

# Toggle a card's discard selection
func toggle_card_for_discard(card) -> void:
	if not is_discard_mode:
		print("[PlayerHand] WARNING: toggle_card_for_discard called but not in discard mode!")
		return
	
	if not card or not is_instance_valid(card):
		print("[PlayerHand] WARNING: toggle_card_for_discard called with invalid card!")
		return
	
	# Prevent double-toggle: if this is the same card and it was just toggled very recently, ignore it
	var current_time_ms = Time.get_ticks_msec()
	if last_toggled_card == card and (current_time_ms - last_toggle_time) < 200:  # 200ms debounce
		print("[PlayerHand] Ignoring rapid double-toggle for card: %s (time diff: %d ms)" % [card.name, current_time_ms - last_toggle_time])
		return
	
	# Check if already selected
	var was_selected = card in selected_for_discard
	
	if was_selected:
		# Deselect
		selected_for_discard.erase(card)
		print("[PlayerHand] Deselected card for discard: %s (%d/%d selected)" % [card.name, selected_for_discard.size(), cards_to_discard])
	else:
		# Select (only if we haven't reached the limit)
		if selected_for_discard.size() < cards_to_discard:
			selected_for_discard.append(card)
			print("[PlayerHand] Selected card for discard: %s (%d/%d selected)" % [card.name, selected_for_discard.size(), cards_to_discard])
		else:
			print("[PlayerHand] Cannot select more cards - already at limit (%d/%d)" % [selected_for_discard.size(), cards_to_discard])
			return
	
	# Track this toggle
	last_toggled_card = card
	last_toggle_time = current_time_ms
	
	_update_discard_visuals()
	_update_discard_status_label()
	
	# Check if we have enough cards selected
	if selected_for_discard.size() == cards_to_discard:
		print("[PlayerHand] Enough cards selected, showing confirmation dialog...")
		_show_discard_confirmation()

# Update visual feedback for discard mode
func _update_discard_visuals() -> void:
	for card in player_hand:
		var is_selected = card in selected_for_discard
		_set_card_discard_visual(card, is_selected)

# Set visual feedback on a card for discard selection (yellow outline)
func _set_card_discard_visual(card, is_selected: bool) -> void:
	# Remove old overlay if it exists
	var old_overlay = card.get_node_or_null("DiscardOverlay")
	if old_overlay:
		old_overlay.queue_free()
	
	if is_selected:
		# Create a yellow outline using a Line2D or multiple ColorRects
		# Using a simple approach with 4 ColorRects for the outline
		var outline_container = Node2D.new()
		outline_container.name = "DiscardOverlay"
		card.add_child(outline_container)
		
		# Card dimensions
		var card_width = 148.0
		var card_height = 209.0
		var outline_width = 4.0
		
		# Top outline
		var top = ColorRect.new()
		top.color = Color.YELLOW
		top.size = Vector2(card_width + outline_width * 2, outline_width)
		top.position = Vector2(-card_width/2 - outline_width, -card_height/2 - outline_width)
		outline_container.add_child(top)
		
		# Bottom outline
		var bottom = ColorRect.new()
		bottom.color = Color.YELLOW
		bottom.size = Vector2(card_width + outline_width * 2, outline_width)
		bottom.position = Vector2(-card_width/2 - outline_width, card_height/2)
		outline_container.add_child(bottom)
		
		# Left outline
		var left = ColorRect.new()
		left.color = Color.YELLOW
		left.size = Vector2(outline_width, card_height)
		left.position = Vector2(-card_width/2 - outline_width, -card_height/2)
		outline_container.add_child(left)
		
		# Right outline
		var right = ColorRect.new()
		right.color = Color.YELLOW
		right.size = Vector2(outline_width, card_height)
		right.position = Vector2(card_width/2, -card_height/2)
		outline_container.add_child(right)
		
		# Set z-index to be on top
		outline_container.z_index = 1000

# Discard the selected cards and call the callback
func _discard_selected_cards() -> void:
	if selected_for_discard.size() != cards_to_discard:
		print("[PlayerHand] ERROR: Wrong number of cards selected for discard!")
		return
	
	var player_deck = get_parent().get_node_or_null("PlayerDeck")
	
	# Discard each selected card
	for card in selected_for_discard:
		if card and is_instance_valid(card):
			# Get card data
			var card_data = null
			if "card_data" in card and card.card_data:
				card_data = card.card_data
			
			# Remove from hand
			player_hand.erase(card)
			
			# Add to discard pile
			if card_data and player_deck and player_deck.has_method("discard_card"):
				player_deck.discard_card(card_data)
			
			# Remove card node
			card.queue_free()
	
	# Update hand positions
	update_hand_positions()
	
	# Store callback before exiting discard mode (since exit_discard_mode clears it)
	var callback_to_call = discard_callback
	
	# Exit discard mode
	exit_discard_mode()
	
	# Call the callback to proceed with turn evaluation
	if callback_to_call.is_valid():
		print("[PlayerHand] Calling discard callback to proceed with turn")
		callback_to_call.call()
	else:
		push_error("[PlayerHand] Discard callback is not valid! Turn will not proceed automatically.")

# Create status label for discard mode
func _create_discard_status_label() -> void:
	if discard_status_label:
		return
	
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	discard_status_label = Label.new()
	discard_status_label.name = "DiscardStatusLabel"
	main_node.add_child(discard_status_label)
	
	# Position at bottom center of screen (above hand)
	var viewport_size = get_viewport().size
	discard_status_label.position = Vector2(viewport_size.x / 2.0, 750)  # Center horizontally, above hand
	discard_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	discard_status_label.add_theme_font_size_override("font_size", 32)
	discard_status_label.add_theme_color_override("font_color", Color.YELLOW)
	discard_status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	discard_status_label.add_theme_constant_override("outline_size", 4)
	discard_status_label.z_index = 1000

# Update status label text
func _update_discard_status_label() -> void:
	if discard_status_label:
		discard_status_label.text = "Select %d card(s) to discard (%d/%d selected)" % [cards_to_discard, selected_for_discard.size(), cards_to_discard]

# Remove status label
func _remove_discard_status_label() -> void:
	if discard_status_label:
		discard_status_label.queue_free()
		discard_status_label = null

# Show confirmation dialog for discarding
func _show_discard_confirmation() -> void:
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	
	# Create confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Discard %d card(s)?\n\nThis will remove the selected cards from your hand." % cards_to_discard
	dialog.title = "Confirm Discard"
	
	# Connect confirmed signal
	dialog.confirmed.connect(_on_discard_confirmed)
	dialog.canceled.connect(_on_discard_canceled)
	
	# Add to scene and show
	main_node.add_child(dialog)
	dialog.popup_centered()

# Called when user confirms discard
func _on_discard_confirmed() -> void:
	print("[PlayerHand] User confirmed discard - proceeding with discard and turn")
	_discard_selected_cards()
	# Note: _discard_selected_cards() will call discard_callback which triggers evaluate_turn()

# Called when user cancels discard
func _on_discard_canceled() -> void:
	print("[PlayerHand] User canceled discard - cards remain selected")
	# Cards stay selected, user can continue selecting/deselecting
