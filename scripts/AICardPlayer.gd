extends Node
class_name AICardPlayer

# References (set by TurnLogic)
var enemy_hand: Node2D = null
var card_manager: Node2D = null
var game_state: Node2D = null
var turn_logic: Node2D = null  # Reference to parent to check is_refilling_hands flag

func setup(enemy_hand_ref: Node2D, card_manager_ref: Node2D, game_state_ref: Node2D, turn_logic_ref: Node2D) -> void:
	enemy_hand = enemy_hand_ref
	card_manager = card_manager_ref
	game_state = game_state_ref
	turn_logic = turn_logic_ref

# Play AI cards from enemy hand to enemy slots
func play_ai_cards() -> void:
	print("[AICardPlayer] ===== play_ai_cards() called =====")
	
	# Check if hand refill is in progress
	var is_refilling = false
	if turn_logic and "is_refilling_hands" in turn_logic:
		is_refilling = turn_logic.is_refilling_hands
	print("[AICardPlayer] is_refilling_hands status: ", is_refilling)
	
	# Wait for hand refill to complete if it's in progress
	if is_refilling:
		print("[AICardPlayer] Hand refill in progress, waiting...")
		var wait_count = 0
		var max_wait = 300  # Maximum 5 seconds (300 frames at 60fps)
		while wait_count < max_wait:
			if turn_logic and "is_refilling_hands" in turn_logic:
				if not turn_logic.is_refilling_hands:
					break
			await get_tree().process_frame
			wait_count += 1
			if wait_count % 60 == 0:  # Log every 60 frames (about 1 second)
				var still_refilling = false
				if turn_logic and "is_refilling_hands" in turn_logic:
					still_refilling = turn_logic.is_refilling_hands
				print("[AICardPlayer] Still waiting for hand refill... (", wait_count, " frames) | is_refilling_hands=", still_refilling)
		
		var still_refilling = false
		if turn_logic and "is_refilling_hands" in turn_logic:
			still_refilling = turn_logic.is_refilling_hands
		if still_refilling:
			print("[AICardPlayer] WARNING: Hand refill wait timed out after ", wait_count, " frames!")
		else:
			print("[AICardPlayer] Hand refill completed after ", wait_count, " frames, proceeding with AI card play")
	else:
		print("[AICardPlayer] No hand refill in progress, proceeding immediately")
	
	# Check if game is still playing before playing AI cards
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[AICardPlayer] Game is over, skipping AI card play")
			return
	
	if not enemy_hand or not card_manager:
		print("[AICardPlayer] ERROR: Cannot play AI cards - missing references")
		return
	
	# Find all enemy slots
	var enemy_slots = []
	var main_node = get_tree().current_scene
	_find_enemy_slots(main_node, enemy_slots)
	
	if enemy_slots.is_empty():
		print("[AICardPlayer] ERROR: No enemy slots found")
		return
	
	print("[AICardPlayer] Found ", enemy_slots.size(), " enemy slots")
	
	# Determine how many cards to play (random, up to number of empty slots)
	var empty_slots = []
	for slot in enemy_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		# Double-check: if card exists but is invalid or queued for deletion, treat as empty
		if current_card:
			if not is_instance_valid(current_card):
				if "current_card" in slot:
					slot.current_card = null
				if slot.has_method("remove_card"):
					slot.remove_card(current_card)
				empty_slots.append(slot)
		else:
			empty_slots.append(slot)
	
	# Get cards from enemy hand
	var available_cards = []
	if "enemy_hand" in enemy_hand:
		available_cards = enemy_hand.enemy_hand.duplicate()
	
	if available_cards.is_empty():
		print("[AICardPlayer] Enemy hand is empty, cannot play cards")
		return
	
	# Determine how many cards to play (random, up to number of empty slots and available cards)
	var cards_to_play = min(empty_slots.size(), available_cards.size(), randi_range(1, 5))
	print("[AICardPlayer] Playing ", cards_to_play, " AI cards from hand (", available_cards.size(), " available)")
	
	# Select random cards from hand and place them
	for i in range(cards_to_play):
		if empty_slots.is_empty() or available_cards.is_empty():
			break
		
		# Pick a random card from available cards
		var random_card_index = randi() % available_cards.size()
		var card_to_play = available_cards[random_card_index]
		available_cards.remove_at(random_card_index)
		
		if not card_to_play or not is_instance_valid(card_to_play):
			print("[AICardPlayer] WARNING: Invalid card selected")
			continue
		
		# Skip cards that are still being added to hand (animating)
		if card_to_play.has_meta("adding_to_hand"):
			print("[AICardPlayer] Skipping card that is still being added to hand: ", card_to_play.name)
			available_cards.append(card_to_play)
			continue
		
		# Additional check: Ensure card's Area2D monitoring is enabled (means it's fully in hand)
		var card_area = card_to_play.get_node_or_null("Area2D")
		if card_area and not card_area.monitoring:
			print("[AICardPlayer] Skipping card with disabled monitoring (still animating): ", card_to_play.name)
			available_cards.append(card_to_play)
			continue
		
		# Get card data for logging
		var card_data = null
		if "card_data" in card_to_play:
			card_data = card_to_play.card_data
		
		# Pick a random empty slot
		var random_slot_index = randi() % empty_slots.size()
		var target_slot = empty_slots[random_slot_index]
		empty_slots.remove_at(random_slot_index)
		
		# Remove card from enemy hand
		if enemy_hand.has_method("remove_card_from_hand"):
			enemy_hand.remove_card_from_hand(card_to_play)
		
		# Disable input for enemy cards (they're AI controlled)
		var area2d = card_to_play.get_node_or_null("Area2D")
		if area2d:
			area2d.input_pickable = false
		
		# Place card in the enemy slot
		print("[AICardPlayer] About to place AI card ", card_to_play.name, " in ", target_slot.name, " | Has adding_to_hand: ", card_to_play.has_meta("adding_to_hand"))
		if target_slot.has_method("snap_card"):
			var result = target_slot.snap_card(card_to_play)
			var card_name = card_data.card_name if card_data else card_to_play.name
			if result == null and card_to_play.has_meta("adding_to_hand"):
				print("[AICardPlayer] WARNING: snap_card() returned null - card may still be animating!")
			else:
				print("[AICardPlayer] Placed AI card ", card_name, " in ", target_slot.name)
		else:
			card_to_play.global_position = target_slot.global_position
			var card_name = card_data.card_name if card_data else card_to_play.name
			print("[AICardPlayer] Positioned AI card ", card_name, " at ", target_slot.name)
		
		# Play the card flip animation to reveal the card
		var animation_player = card_to_play.get_node_or_null("AnimationPlayer")
		if animation_player:
			if animation_player.has_animation("card_flip"):
				animation_player.play("card_flip")
				await get_tree().create_timer(0.2).timeout
		
		# Small delay between placing cards for better visual effect
		if i < cards_to_play - 1:
			await get_tree().create_timer(0.1).timeout

# Recursively find all enemy slots
func _find_enemy_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("EnemySlot"):
		result.append(node)
	
	for child in node.get_children():
		_find_enemy_slots(child, result)

