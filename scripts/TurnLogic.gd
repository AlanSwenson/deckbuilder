extends Node2D

const CARD_SCENE_PATH = "res://scenes/Card.tscn"

var card_manager: Node2D = null
var enemy_deck: Node2D = null
var player_deck: Node2D = null
var player_hand: Node2D = null
var card_scene: PackedScene = null

func _ready() -> void:
	# Load card scene
	card_scene = preload(CARD_SCENE_PATH)
	
	# Find references
	card_manager = get_parent().get_node_or_null("CardManager")
	enemy_deck = get_parent().get_node_or_null("EnemyDeck")
	player_deck = get_parent().get_node_or_null("PlayerDeck")
	player_hand = get_parent().get_node_or_null("PlayerHand")
	
	if not card_manager:
		print("[TurnLogic] ERROR: CardManager not found")
	if not enemy_deck:
		print("[TurnLogic] ERROR: EnemyDeck not found")
	if not player_deck:
		print("[TurnLogic] ERROR: PlayerDeck not found")
	if not player_hand:
		print("[TurnLogic] ERROR: PlayerHand not found")
	
	# Connect to Play Hand button
	var play_hand_button = get_parent().get_node_or_null("PlayHandButton")
	if play_hand_button:
		play_hand_button.pressed.connect(_on_play_hand_pressed)
		print("[TurnLogic] Connected to PlayHandButton")
	else:
		print("[TurnLogic] WARNING: PlayHandButton not found")

func _on_play_hand_pressed() -> void:
	print("[TurnLogic] Play Hand button pressed - evaluating turn")
	evaluate_turn()

func evaluate_turn() -> void:
	# First, determine AI cards to play and place them in enemy slots
	play_ai_cards()
	
	# Wait a moment for AI cards to be placed
	await get_tree().create_timer(0.5).timeout
	
	# Resolve turn - for now just assume everything resolves
	resolve_turn()
	
	# Clean up and prepare for next turn
	cleanup_turn()

func play_ai_cards() -> void:
	if not enemy_deck or not card_manager:
		print("[TurnLogic] ERROR: Cannot play AI cards - missing references")
		return
	
	# Find all enemy slots
	var enemy_slots = []
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	_find_enemy_slots(main_node, enemy_slots)
	
	if enemy_slots.is_empty():
		print("[TurnLogic] ERROR: No enemy slots found")
		return
	
	print("[TurnLogic] Found ", enemy_slots.size(), " enemy slots")
	
	# Determine how many cards to play (random, up to number of empty slots)
	var empty_slots = []
	for slot in enemy_slots:
		# Check if slot is empty by checking current_card property or method
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if not current_card:
			empty_slots.append(slot)
	
	var cards_to_play = min(empty_slots.size(), randi_range(1, 5))  # Play 1-5 random cards
	print("[TurnLogic] Playing ", cards_to_play, " AI cards")
	
	# Draw random cards from enemy deck and place them
	for i in range(cards_to_play):
		if empty_slots.is_empty():
			break
		
		# Draw a card from enemy deck
		var card_data = null
		if enemy_deck.has_method("draw_card"):
			card_data = enemy_deck.draw_card()
		
		if not card_data:
			print("[TurnLogic] WARNING: Could not draw card from enemy deck")
			continue
		
		# Pick a random empty slot
		var random_index = randi() % empty_slots.size()
		var target_slot = empty_slots[random_index]
		empty_slots.remove_at(random_index)
		
		# Create card instance
		var new_card = card_scene.instantiate()
		if not new_card:
			print("[TurnLogic] ERROR: Failed to instantiate card scene")
			continue
		
		# Give card a unique name
		var card_number = 1000 + i  # Use high numbers to distinguish from player cards
		new_card.name = "EnemyCard" + str(card_number)
		
		# Set card data
		if new_card.has_method("set_card_data"):
			new_card.set_card_data(card_data)
		
		# Disable input for enemy cards (they're AI controlled)
		var area2d = new_card.get_node_or_null("Area2D")
		if area2d:
			area2d.input_pickable = false
		
		# Add card to CardManager
		card_manager.add_child(new_card)
		
		# Wait a frame to ensure card is in tree
		await get_tree().process_frame
		
		# Place card in the enemy slot
		if target_slot.has_method("snap_card"):
			target_slot.snap_card(new_card)
			print("[TurnLogic] Placed AI card ", card_data.card_name, " in ", target_slot.name)
		else:
			# Fallback: manually position the card
			new_card.global_position = target_slot.global_position
			print("[TurnLogic] Positioned AI card ", card_data.card_name, " at ", target_slot.name)
		
		# Play the card flip animation to reveal the card
		var animation_player = new_card.get_node_or_null("AnimationPlayer")
		if animation_player:
			if animation_player.has_animation("card_flip"):
				animation_player.play("card_flip")
				# Wait for animation to complete (0.2 seconds based on animation length)
				await get_tree().create_timer(0.2).timeout
			else:
				print("[TurnLogic] WARNING: card_flip animation not found in AnimationPlayer")
		else:
			print("[TurnLogic] WARNING: AnimationPlayer not found on enemy card")
		
		# Small delay between placing cards for better visual effect
		if i < cards_to_play - 1:  # Don't delay after the last card
			await get_tree().create_timer(0.1).timeout

# Resolve the turn (for now, just assume everything resolves)
func resolve_turn() -> void:
	print("[TurnLogic] Resolving turn...")
	# TODO: Calculate damage, healing, etc.
	# For now, just assume everything resolves
	pass

# Clean up after turn resolution
func cleanup_turn() -> void:
	print("[TurnLogic] Cleaning up turn...")
	
	# Move all cards from player slots to discard
	discard_player_slot_cards()
	
	# Clear enemy slots (for now, just remove the cards)
	clear_enemy_slots()
	
	# Refill player hand to original amount
	refill_player_hand()

# Move all cards from player slots to discard slot
func discard_player_slot_cards() -> void:
	if not player_deck:
		print("[TurnLogic] ERROR: Cannot discard cards - PlayerDeck not found")
		return
	
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_slots = []
	_find_player_slots(main_node, player_slots)
	
	var discard_slot = main_node.get_node_or_null("DiscardSlotPlayer")
	if not discard_slot:
		print("[TurnLogic] WARNING: DiscardSlotPlayer not found, cards will be removed but not visually placed")
	
	print("[TurnLogic] Discarding cards from ", player_slots.size(), " player slots")
	
	for slot in player_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card):
			# Get card data and add to discard pile
			if "card_data" in current_card and current_card.card_data:
				player_deck.discard_card(current_card.card_data)
				print("[TurnLogic] Discarded card: ", current_card.card_data.card_name)
			
			# Remove card from slot
			if slot.has_method("remove_card"):
				slot.remove_card(current_card)
			
			# Move card to discard slot position if it exists
			if discard_slot:
				# Animate card to discard position
				var tween = get_tree().create_tween()
				tween.tween_property(current_card, "global_position", discard_slot.global_position, 0.3)
				await tween.finished
			
			# Remove the card node
			current_card.queue_free()
			await get_tree().process_frame

# Clear enemy slots (remove enemy cards)
func clear_enemy_slots() -> void:
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var enemy_slots = []
	_find_enemy_slots(main_node, enemy_slots)
	
	print("[TurnLogic] Clearing ", enemy_slots.size(), " enemy slots")
	
	for slot in enemy_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card):
			# Remove card from slot
			if slot.has_method("remove_card"):
				slot.remove_card(current_card)
			
			# Remove the card node
			current_card.queue_free()
			await get_tree().process_frame

# Refill player hand to original amount (10 cards)
func refill_player_hand() -> void:
	if not player_hand or not player_deck:
		print("[TurnLogic] ERROR: Cannot refill hand - missing references")
		return
	
	# Get current hand size
	var current_hand_size = 0
	if "player_hand" in player_hand:
		current_hand_size = player_hand.player_hand.size()
	
	var target_hand_size = 10  # HAND_COUNT
	var cards_needed = target_hand_size - current_hand_size
	
	if cards_needed <= 0:
		print("[TurnLogic] Hand is already full (", current_hand_size, " cards)")
		return
	
	print("[TurnLogic] Drawing ", cards_needed, " cards to refill hand")
	
	# Draw cards and add them to hand
	for i in range(cards_needed):
		var card_data = player_deck.draw_card()
		if not card_data:
			print("[TurnLogic] WARNING: Could not draw card ", i + 1, " - deck may be empty")
			break
		
		# Create card instance
		var new_card = card_scene.instantiate()
		if not new_card:
			print("[TurnLogic] ERROR: Failed to instantiate card scene")
			continue
		
		# Get card number from PlayerHand
		var card_number = 1
		if "card_id_counter" in player_hand:
			card_number = player_hand.card_id_counter
			player_hand.card_id_counter += 1
		
		new_card.name = "Card" + str(card_number)
		
		# Set card number
		if new_card.has_method("set_card_number"):
			new_card.set_card_number(card_number)
		new_card.set_meta("card_number", card_number)
		
		# Set card data
		if new_card.has_method("set_card_data"):
			new_card.set_card_data(card_data)
		
		# Position card at deck location
		var deck_slot = get_parent().get_node_or_null("DeckSlotPlayer")
		if deck_slot:
			var deck_local_position = card_manager.to_local(deck_slot.global_position)
			new_card.position = deck_local_position
		
		# Add card to CardManager
		card_manager.add_child(new_card)
		
		# Wait a frame to ensure card is in tree
		await get_tree().process_frame
		
		# Verify card is at deck position
		if deck_slot:
			var deck_local_position = card_manager.to_local(deck_slot.global_position)
			new_card.position = deck_local_position
		
		# Set card data
		if new_card.has_method("set_card_data"):
			new_card.set_card_data(card_data)
			if new_card.has_method("update_card_display"):
				new_card.update_card_display()
		
		# Calculate target position in hand
		var current_hand_size_after_add = current_hand_size + i
		var target_x = 0.0
		if player_hand.has_method("calculate_card_position"):
			target_x = player_hand.calculate_card_position(current_hand_size_after_add)
		else:
			# Fallback calculation using constants
			var card_width = 100  # CARD_WIDTH constant
			var center_x = player_hand.center_screen_x if "center_screen_x" in player_hand else get_viewport().size.x / 2
			var total_width = (current_hand_size_after_add) * card_width
			target_x = center_x + current_hand_size_after_add * card_width - total_width / 2
		
		var hand_y = 890  # HAND_Y_POSITION constant
		var target_position = Vector2(target_x, hand_y)
		
		# Play flip animation and animate to hand position
		var animation_player = new_card.get_node_or_null("AnimationPlayer")
		if animation_player and animation_player.has_animation("card_flip"):
			animation_player.play("card_flip")
		
		# Animate to hand position
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(new_card, "position", target_position, 0.2)
		
		# Add to hand array
		if "player_hand" in player_hand:
			player_hand.player_hand.append(new_card)
		
		# Wait for animation to complete
		await tween.finished
		
		# Update hand positions to ensure proper spacing
		if player_hand.has_method("update_hand_positions"):
			player_hand.update_hand_positions()
		
		# Small delay between cards
		if i < cards_needed - 1:
			await get_tree().create_timer(0.05).timeout

# Recursively find all enemy slots
func _find_enemy_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("EnemySlot"):
		result.append(node)
	
	for child in node.get_children():
		_find_enemy_slots(child, result)

# Recursively find all player slots
func _find_player_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("PlayerSlot"):
		result.append(node)
	
	for child in node.get_children():
		_find_player_slots(child, result)
