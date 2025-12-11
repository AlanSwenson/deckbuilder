extends Node2D

# Input state
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var dragged_card: Node2D = null  # Track which specific card is being dragged
var dragged_card_start_position: Vector2 = Vector2.ZERO  # Store original position before drag
var dragged_card_initial_mouse_pos: Vector2 = Vector2.ZERO  # Mouse position when drag started
var hovered_card: Node2D = null  # Track which card is currently being hovered

# Public getter for dragged card (so other scripts can check if a card is being dragged)
func get_dragged_card() -> Node2D:
	return dragged_card

# Constants
const HOVER_SCALE: float = 1.15  # Scale factor when hovering (15% bigger)
const HOVER_ANIMATION_DURATION: float = 0.15  # Animation duration in seconds
const RETURN_ANIMATION_DURATION: float = 0.2  # Animation duration for returning card
const CARD_WIDTH: float = 148.0  # Card width in pixels
const CARD_HEIGHT: float = 209.0  # Card height in pixels

# References
var card_manager: Node2D = null

func _ready() -> void:
	# Find CardManager
	card_manager = get_node_or_null("../CardManager")
	if not card_manager:
		card_manager = get_tree().current_scene.get_node_or_null("CardManager")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Update card position while dragging
	if is_dragging and dragged_card:
		var mouse_pos = get_global_mouse_position()
		var target_position = mouse_pos - drag_offset
		
		# Clamp card position to keep it within screen bounds
		var viewport_size = get_viewport().get_visible_rect().size
		var half_card_width = CARD_WIDTH / 2.0
		var half_card_height = CARD_HEIGHT / 2.0
		
		# Clamp X position (left and right edges)
		target_position.x = clamp(
			target_position.x,
			half_card_width,
			viewport_size.x - half_card_width
		)
		
		# Clamp Y position (top and bottom edges)
		target_position.y = clamp(
			target_position.y,
			half_card_height,
			viewport_size.y - half_card_height
		)
		
		dragged_card.global_position = target_position
		
		# Check if we should show reorder preview (horizontal movement, not too far vertically)
		if _should_reorder_hand():
			_update_hand_reorder_preview(mouse_pos)
		
		# Ensure dragged card stays on top while dragging
		# (call last to override any other z_index changes)
		_keep_dragged_card_on_top()
		
		# Also defer to end of frame to ensure z_index is absolutely last
		call_deferred("_keep_dragged_card_on_top")
		
		# Debug log every 60 frames while dragging
		if Engine.get_process_frames() % 60 == 0:
			print("[InputManager] _process() - Dragging ", dragged_card.name,
				" | Mouse: ", mouse_pos, " | Card: ", dragged_card.global_position)
	
	# Check if mouse button was released (global check)
	if is_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if dragged_card:
			print("[InputManager] _process() - DRAGGING STOPPED (mouse released globally) for ",
				dragged_card.name)
			_handle_card_release(dragged_card)
			is_dragging = false
			dragged_card = null

# Handle input events from the Area2D
# card parameter is passed from the lambda that captures it
func _on_card_input_event(
	card: Node2D, _viewport: Node, event: InputEvent, _shape_idx: int
) -> void:
	print("[InputManager] _on_card_input_event() - Event from ", card.name,
		" | Event type: ", event.get_class())
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				print("[InputManager] _on_card_input_event() - Left mouse button PRESSED on ",
					card.name)
				# Only start dragging if we're not already dragging another card
				if not is_dragging:
					_start_dragging(card)
			else:
				print("[InputManager] _on_card_input_event() - Left mouse button RELEASED on ",
					card.name)
				# Only stop dragging if this is the card we're dragging
				if is_dragging and dragged_card == card:
					_handle_card_release(card)
					is_dragging = false
					dragged_card = null
					print("[InputManager] _on_card_input_event() - DRAGGING STOPPED for ",
						card.name)

# Start dragging a card
func _start_dragging(card: Node2D) -> void:
	is_dragging = true
	dragged_card = card
	# Store the starting position before dragging
	if card.has_meta("starting_position"):
		dragged_card_start_position = card.get_meta("starting_position")
	else:
		dragged_card_start_position = card.position
	var mouse_pos = get_global_mouse_position()
	dragged_card_initial_mouse_pos = mouse_pos
	drag_offset = mouse_pos - card.global_position
	# Reset hover effect when starting to drag
	_reset_hover_effect()
	# Bring card to top immediately when dragging starts (call after reset to ensure it's set)
	_bring_dragged_card_to_top()
	# Force z_index one more time to ensure it's set before next frame
	card.z_index = 1000
	print("[InputManager] DRAGGING STARTED for ", card.name, " | Mouse: ", mouse_pos,
		" | Card: ", card.global_position, " | Offset: ", drag_offset)

# Handle card release (mouse button released)
func _handle_card_release(card: Node2D) -> void:
	if not card_manager:
		return
	
	# Check if card was snapped to a slot
	var was_snapped = false
	if card_manager.has_method("check_and_snap_to_slot"):
		was_snapped = card_manager.check_and_snap_to_slot(card)
	
	if was_snapped:
		# Card was snapped to a slot
		# If card was in hand, remove it from hand
		if _is_card_in_hand(card):
			if card_manager.has_method("notify_card_played"):
				card_manager.notify_card_played(card)
		# Note: If card was already in a slot, the swap logic in CardManager handles it
	elif _is_mouse_over_hand_area():
		# Card released over hand area - add it back if not already in hand
		if not _is_card_in_hand(card):
			_add_card_to_hand(card)
		elif _should_reorder_hand():
			# Reorder the hand based on horizontal position
			var mouse_pos = get_global_mouse_position()
			_reorder_hand_on_release(mouse_pos)
		else:
			_return_card_to_start_position(card)
	elif _should_reorder_hand():
		# Reorder the hand based on horizontal position
		var mouse_pos = get_global_mouse_position()
		_reorder_hand_on_release(mouse_pos)
	else:
		_return_card_to_start_position(card)

# Handle mouse entering a card area (hover start)
func _on_card_mouse_entered(card: Node2D) -> void:
	# Don't apply hover effect if dragging
	if is_dragging:
		return
	
	# Reset previous hovered card if different
	if hovered_card and hovered_card != card:
		_reset_card_scale(hovered_card)
	
	hovered_card = card
	_apply_hover_effect(card)
	_set_cursor_hand(true)

# Handle mouse exiting a card area (hover end)
func _on_card_mouse_exited(card: Node2D) -> void:
	# Don't reset hover if we're dragging this card
	if is_dragging and dragged_card == card:
		return
	
	if hovered_card == card:
		_reset_hover_effect()

# Apply hover effect to a card (scale up)
func _apply_hover_effect(card: Node2D) -> void:
	if not card or not is_instance_valid(card):
		return
	
	# Store original scale if not already stored
	if not card.has_meta("original_scale"):
		card.set_meta("original_scale", card.scale)
	
	# Animate scale up
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		card, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), HOVER_ANIMATION_DURATION
	)
	tween.tween_callback(func(): _bring_card_to_front(card))

# Reset hover effect on current hovered card
func _reset_hover_effect() -> void:
	if hovered_card:
		_reset_card_scale(hovered_card)
	hovered_card = null
	_set_cursor_hand(false)

# Reset a card's scale to original
func _reset_card_scale(card: Node2D) -> void:
	if not card or not is_instance_valid(card):
		return
	
	if card.has_meta("original_scale"):
		var original_scale = card.get_meta("original_scale")
		var tween = get_tree().create_tween()
		tween.tween_property(card, "scale", original_scale, HOVER_ANIMATION_DURATION)
		tween.tween_callback(func(): card.remove_meta("original_scale"))
		tween.tween_callback(func(): _restore_card_z_index(card))
	else:
		# Fallback: just reset to 1,1
		var tween = get_tree().create_tween()
		tween.tween_property(card, "scale", Vector2.ONE, HOVER_ANIMATION_DURATION)
		tween.tween_callback(func(): _restore_card_z_index(card))

# Bring dragged card to top immediately when dragging starts
func _bring_dragged_card_to_top() -> void:
	if not dragged_card or not is_instance_valid(dragged_card):
		return
	
	# Store original z_index if not stored
	if not dragged_card.has_meta("dragged_original_z_index"):
		dragged_card.set_meta("dragged_original_z_index", dragged_card.z_index)
	
	# Bring to very top (high z_index so it's above everything - slots, other cards, etc.)
	# Use 1000 which is above slot cards (max ~110) and hand cards (max ~100) but below max (4096)
	dragged_card.z_index = 1000

# Keep dragged card on top while dragging
func _keep_dragged_card_on_top() -> void:
	if not dragged_card or not is_instance_valid(dragged_card):
		return
	
	# Always set to high z_index to ensure it's above everything (slots, other cards, etc.)
	# Use 1000 which is above slot cards (max ~110) and hand cards (max ~100) but below max (4096)
	# Set unconditionally every frame to override any other code that might change it
	dragged_card.z_index = 1000
	
	# Also ensure all other cards in slots maintain their lower z_index
	# This prevents other slotted cards from accidentally getting high z_index
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	if main_node:
		var card_slots = []
		_find_all_card_slots(main_node, card_slots)
		for slot in card_slots:
			if slot.has_method("get_current_card"):
				var slot_card = slot.get_current_card()
				if slot_card and slot_card != dragged_card and slot_card.is_inside_tree():
					# Ensure slot card has lower z_index than dragged card
					# Restore proper slot z_index based on card number
					if slot_card.z_index >= 1000:
						var card_number = 1  # Default
						if slot_card.has_meta("card_number"):
							card_number = slot_card.get_meta("card_number")
						else:
							var label = slot_card.get_node_or_null("CardNumberLabel")
							if label and label.text.is_valid_int():
								card_number = label.text.to_int()
						slot_card.z_index = 100 + card_number

# Helper to find all card slots recursively
func _find_all_card_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("CardSlot"):
		result.append(node)
	for child in node.get_children():
		_find_all_card_slots(child, result)

# Bring card to front by adjusting z_index (for hover effect)
func _bring_card_to_front(card: Node2D) -> void:
	if not card or not is_instance_valid(card):
		return
	
	# Don't change z_index if this card is being dragged (it's already on top)
	if card == dragged_card:
		return
	
	# Store original z_index if not stored
	if not card.has_meta("original_z_index"):
		card.set_meta("original_z_index", card.z_index)
	
	# Bring to front (higher z_index - use 200 to be above all hand cards)
	# Hand cards use (hand_size - index) * 10, so max would be hand_size * 10
	# Using 200 ensures hovered card is always on top
	card.z_index = 200

# Restore a card's z_index to its original value
func _restore_card_z_index(card: Node2D) -> void:
	if not card or not is_instance_valid(card):
		return
	
	# Restore dragged card's original z_index
	if card.has_meta("dragged_original_z_index"):
		var original_z = card.get_meta("dragged_original_z_index")
		card.z_index = original_z
		card.remove_meta("dragged_original_z_index")
		# After restoring, let hand update set the proper z_index based on position
		return
	
	# For hover effects: update z_index based on current hand position instead of restoring
	# This ensures correct layering even if the card was reordered while hovering
	if card.has_meta("original_z_index"):
		card.remove_meta("original_z_index")
		# Update z_index based on current position in hand
		_update_card_z_index_from_hand_position(card)

# Return a card to its starting position with animation
func _return_card_to_start_position(card: Node2D) -> void:
	if not card or not is_instance_valid(card):
		return
	
	# Use the stored starting position from when drag began
	var target_position = dragged_card_start_position
	
	# Animate the card back to its starting position
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "position", target_position, RETURN_ANIMATION_DURATION)
	print(
		"[InputManager] Returning card to start position: ",
		card.name,
		" -> ",
		target_position
	)

# Check if we should reorder the hand (horizontal movement, not too far vertically)
func _should_reorder_hand() -> bool:
	if not is_dragging or not dragged_card:
		return false
	
	# Check if the card overlaps with the hand area
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_hand = main_node.get_node_or_null("PlayerHand")
	if not player_hand:
		return false
	
	# Check if card overlaps with hand area (any part of card touching hand)
	if player_hand.has_method("does_card_overlap_hand_area"):
		return player_hand.does_card_overlap_hand_area(dragged_card)
	
	# Fallback: check if card is in hand
	if player_hand.has_method("is_card_in_hand"):
		return player_hand.is_card_in_hand(dragged_card)
	
	return false

# Update hand reorder preview while dragging (show where card would be placed)
func _update_hand_reorder_preview(_mouse_pos: Vector2) -> void:
	# This could show visual feedback, but for now we'll just handle it on release
	pass

# Reorder the hand when card is released
func _reorder_hand_on_release(mouse_pos: Vector2) -> void:
	if not dragged_card:
		return
	
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_hand = main_node.get_node_or_null("PlayerHand")
	if not player_hand or not player_hand.has_method("reorder_card_in_hand"):
		_return_card_to_start_position(dragged_card)
		return
	
	# Calculate target index based on horizontal mouse position
	var target_index = player_hand.calculate_index_from_x(mouse_pos.x)
	player_hand.reorder_card_in_hand(dragged_card, target_index)
	print(
		"[InputManager] Reordered card in hand: ",
		dragged_card.name,
		" to index: ",
		target_index
	)

# Check if a card is in the player's hand
func _is_card_in_hand(card: Node2D) -> bool:
	if not card:
		return false
	
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_hand = main_node.get_node_or_null("PlayerHand")
	
	if player_hand and player_hand.has_method("is_card_in_hand"):
		return player_hand.is_card_in_hand(card)
	return false

# Check if mouse is over the hand area
func _is_mouse_over_hand_area() -> bool:
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_hand = main_node.get_node_or_null("PlayerHand")
	
	if not player_hand or not player_hand.has_method("is_position_in_hand_area"):
		return false
	
	var mouse_pos = get_global_mouse_position()
	return player_hand.is_position_in_hand_area(mouse_pos)

# Add a card to the hand
func _add_card_to_hand(card: Node2D) -> void:
	if not card:
		return
	
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_hand = main_node.get_node_or_null("PlayerHand")
	
	if player_hand and player_hand.has_method("add_card_to_hand_at_index"):
		# Calculate target index based on mouse position
		var mouse_pos = get_global_mouse_position()
		var target_index = player_hand.calculate_index_from_x(mouse_pos.x)
		player_hand.add_card_to_hand_at_index(card, target_index)
		print(
			"[InputManager] Added card to hand: ",
			card.name,
			" at index: ",
			target_index
		)

# Update a card's z_index based on its current position in the hand
func _update_card_z_index_from_hand_position(card: Node2D) -> void:
	if not card:
		return
	
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_hand_node = main_node.get_node_or_null("PlayerHand")
	
	if not player_hand_node or not player_hand_node.has_method("update_card_z_index"):
		return
	
	# Use PlayerHand's method to update z_index based on current position
	player_hand_node.update_card_z_index(card)

# Set cursor to hand or arrow
func _set_cursor_hand(is_hand: bool) -> void:
	if is_hand:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
