extends Node2D

const CARD_SCENE_PATH = "res://scenes/Card.tscn"

var card_manager: Node2D = null
var enemy_deck: Node2D = null
var player_deck: Node2D = null
var player_hand: Node2D = null
var enemy_hand: Node2D = null
var card_scene: PackedScene = null
var game_state: Node2D = null
var is_refilling_hands: bool = false  # Track if hands are currently being refilled

func _ready() -> void:
	# Load card scene
	card_scene = preload(CARD_SCENE_PATH)
	
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
	
	# Connect to Play Hand button
	var play_hand_button = get_parent().get_node_or_null("PlayHandButton")
	if play_hand_button:
		play_hand_button.pressed.connect(_on_play_hand_pressed)
		print("[TurnLogic] Connected to PlayHandButton")
	else:
		print("[TurnLogic] WARNING: PlayHandButton not found")

func _on_play_hand_pressed() -> void:
	print("[TurnLogic] ===== Play Hand button pressed - evaluating turn =====")
	evaluate_turn()

func evaluate_turn() -> void:
	# Check if game is still playing before starting turn
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game is over, cannot evaluate turn")
			return
	
	# First, determine AI cards to play and place them in enemy slots
	# Make sure we wait for play_ai_cards to complete (including any wait for hand refill)
	await play_ai_cards()
	
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
	resolve_turn()
	
	# Check again after resolving turn (in case HP reached 0)
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game ended during turn resolution, skipping cleanup")
			return
	
	# Clean up and prepare for next turn (but DON'T play enemy cards - that happens at the START of next turn)
	cleanup_turn()

func play_ai_cards() -> void:
	print("[TurnLogic] ===== play_ai_cards() called =====")
	print("[TurnLogic] is_refilling_hands status: ", is_refilling_hands)
	
	# Wait for hand refill to complete if it's in progress
	# Use a coroutine-style wait that actually works
	if is_refilling_hands:
		print("[TurnLogic] Hand refill in progress, waiting...")
		var wait_count = 0
		var max_wait = 300  # Maximum 5 seconds (300 frames at 60fps)
		while is_refilling_hands and wait_count < max_wait:
			await get_tree().process_frame
			wait_count += 1
			if wait_count % 60 == 0:  # Log every 60 frames (about 1 second)
				print("[TurnLogic] Still waiting for hand refill... (", wait_count, " frames) | is_refilling_hands=", is_refilling_hands)
		
		if is_refilling_hands:
			print("[TurnLogic] WARNING: Hand refill wait timed out after ", wait_count, " frames!")
		else:
			print("[TurnLogic] Hand refill completed after ", wait_count, " frames, proceeding with AI card play")
	else:
		print("[TurnLogic] No hand refill in progress, proceeding immediately")
	
	# Check if game is still playing before playing AI cards
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game is over, skipping AI card play")
			return
	
	if not enemy_hand or not card_manager:
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
		
		# Double-check: if card exists but is invalid or queued for deletion, treat as empty
		if current_card:
			if not is_instance_valid(current_card):
				# Card is invalid, clear the slot reference
				if "current_card" in slot:
					slot.current_card = null
				if slot.has_method("remove_card"):
					slot.remove_card(current_card)
				empty_slots.append(slot)
			else:
				# Card exists and is valid, slot is not empty
				pass
		else:
			# No card in slot, it's empty
			empty_slots.append(slot)
	
	# Get cards from enemy hand
	var available_cards = []
	if "enemy_hand" in enemy_hand:
		available_cards = enemy_hand.enemy_hand.duplicate()  # Make a copy to avoid modifying while iterating
	
	if available_cards.is_empty():
		print("[TurnLogic] Enemy hand is empty, cannot play cards")
		return
	
	# Determine how many cards to play (random, up to number of empty slots and available cards)
	var cards_to_play = min(empty_slots.size(), available_cards.size(), randi_range(1, 5))  # Play 1-5 random cards
	print("[TurnLogic] Playing ", cards_to_play, " AI cards from hand (", available_cards.size(), " available)")
	
	# Select random cards from hand and place them
	for i in range(cards_to_play):
		if empty_slots.is_empty() or available_cards.is_empty():
			break
		
		# Pick a random card from available cards
		var random_card_index = randi() % available_cards.size()
		var card_to_play = available_cards[random_card_index]
		available_cards.remove_at(random_card_index)
		
		if not card_to_play or not is_instance_valid(card_to_play):
			print("[TurnLogic] WARNING: Invalid card selected")
			continue
		
		# Skip cards that are still being added to hand (animating)
		if card_to_play.has_meta("adding_to_hand"):
			print("[TurnLogic] Skipping card that is still being added to hand: ", card_to_play.name)
			# Put it back in available cards and try again
			available_cards.append(card_to_play)
			continue
		
		# Additional check: Ensure card's Area2D monitoring is enabled (means it's fully in hand)
		var card_area = card_to_play.get_node_or_null("Area2D")
		if card_area and not card_area.monitoring:
			print("[TurnLogic] Skipping card with disabled monitoring (still animating): ", card_to_play.name)
			# Put it back in available cards and try again
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
		print("[TurnLogic] About to place AI card ", card_to_play.name, " in ", target_slot.name, " | Has adding_to_hand: ", card_to_play.has_meta("adding_to_hand"))
		if target_slot.has_method("snap_card"):
			var result = target_slot.snap_card(card_to_play)
			var card_name = card_data.card_name if card_data else card_to_play.name
			if result == null and card_to_play.has_meta("adding_to_hand"):
				print("[TurnLogic] WARNING: snap_card() returned null - card may still be animating!")
			else:
				print("[TurnLogic] Placed AI card ", card_name, " in ", target_slot.name)
		else:
			# Fallback: manually position the card
			card_to_play.global_position = target_slot.global_position
			var card_name = card_data.card_name if card_data else card_to_play.name
			print("[TurnLogic] Positioned AI card ", card_name, " at ", target_slot.name)
		
		# Play the card flip animation to reveal the card
		var animation_player = card_to_play.get_node_or_null("AnimationPlayer")
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

# Resolve the turn - calculate damage and apply it
func resolve_turn() -> void:
	print("[TurnLogic] Resolving turn...")
	
	# Check if game is still playing
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game is over, skipping turn resolution")
			return
	
	# Calculate player damage to enemy
	var player_damage = calculate_player_damage()
	if player_damage > 0:
		if game_state and game_state.has_method("damage_enemy"):
			game_state.damage_enemy(player_damage)
	
	# Calculate enemy damage to player
	var enemy_damage = calculate_enemy_damage()
	if enemy_damage > 0:
		if game_state and game_state.has_method("damage_player"):
			game_state.damage_player(enemy_damage)
	
	# Apply healing (if any)
	apply_healing()

# Calculate total damage from player cards
func calculate_player_damage() -> int:
	var total_damage = 0
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_slots = []
	_find_player_slots(main_node, player_slots)
	
	for slot in player_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card):
			var card_data = null
			if "card_data" in current_card:
				card_data = current_card.card_data
			
			if card_data:
				# Use damage_value if available, otherwise use damage_range
				var damage = 0
				if card_data.damage_value > 0:
					damage = card_data.damage_value
				elif card_data.damage_range.x > 0 or card_data.damage_range.y > 0:
					damage = randi_range(card_data.damage_range.x, card_data.damage_range.y)
				
				total_damage += damage
				print("[TurnLogic] Player card ", card_data.card_name, " deals ", damage, " damage")
	
	print("[TurnLogic] Total player damage: ", total_damage)
	return total_damage

# Calculate total damage from enemy cards
func calculate_enemy_damage() -> int:
	var total_damage = 0
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var enemy_slots = []
	_find_enemy_slots(main_node, enemy_slots)
	
	for slot in enemy_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card):
			var card_data = null
			if "card_data" in current_card:
				card_data = current_card.card_data
			
			if card_data:
				# Use damage_value if available, otherwise use damage_range
				var damage = 0
				if card_data.damage_value > 0:
					damage = card_data.damage_value
				elif card_data.damage_range.x > 0 or card_data.damage_range.y > 0:
					damage = randi_range(card_data.damage_range.x, card_data.damage_range.y)
				
				total_damage += damage
				print("[TurnLogic] Enemy card ", card_data.card_name, " deals ", damage, " damage")
	
	print("[TurnLogic] Total enemy damage: ", total_damage)
	return total_damage

# Apply healing from cards
func apply_healing() -> void:
	if not game_state:
		return
	
	# Player healing
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_slots = []
	_find_player_slots(main_node, player_slots)
	
	var player_heal = 0
	for slot in player_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card):
			var card_data = null
			if "card_data" in current_card:
				card_data = current_card.card_data
			
			if card_data and card_data.heal_value > 0:
				player_heal += card_data.heal_value
	
	if player_heal > 0 and game_state.has_method("heal_player"):
		game_state.heal_player(player_heal)
	
	# Enemy healing
	var enemy_slots = []
	_find_enemy_slots(main_node, enemy_slots)
	
	var enemy_heal = 0
	for slot in enemy_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card):
			var card_data = null
			if "card_data" in current_card:
				card_data = current_card.card_data
			
			if card_data and card_data.heal_value > 0:
				enemy_heal += card_data.heal_value
	
	if enemy_heal > 0 and game_state.has_method("heal_enemy"):
		game_state.heal_enemy(enemy_heal)

# Clean up after turn resolution
func cleanup_turn() -> void:
	# Check if game is over before continuing
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game is over, skipping cleanup")
			return
	
	print("[TurnLogic] Cleaning up turn...")
	
	# Move all cards from player slots to discard
	discard_player_slot_cards()
	
	# Check if game ended during discard
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game ended during discard, stopping cleanup")
			return
	
	# Clear enemy slots (for now, just remove the cards)
	clear_enemy_slots()
	
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
			await refill_player_hand()
			print("[TurnLogic] Player hand refill complete, is_refilling_hands=", is_refilling_hands)
			
			# Check again after refilling player hand
			if game_state and game_state.has_method("is_game_playing"):
				if game_state.is_game_playing():
					print("[TurnLogic] Starting enemy hand refill, is_refilling_hands=", is_refilling_hands)
					await refill_enemy_hand()
					print("[TurnLogic] Enemy hand refill complete, is_refilling_hands=", is_refilling_hands)
					print("[TurnLogic] Hands refilled. Enemy will play cards when 'Play Hand' is pressed next.")
				else:
					print("[TurnLogic] Game ended during player hand refill, stopping enemy hand refill")
			else:
				print("[TurnLogic] Game ended during player hand refill, stopping enemy hand refill")
			
			# Always clear the flag when refill is done (whether successful or not)
			is_refilling_hands = false
			print("[TurnLogic] Hand refill complete - setting is_refilling_hands=false")
		else:
			print("[TurnLogic] Game is over, skipping hand refill")
			is_refilling_hands = false
	else:
		print("[TurnLogic] Game is over, skipping hand refill")
		is_refilling_hands = false

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
		# Check if game ended during discard
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[TurnLogic] Game ended during player slot discard, stopping")
				return
		
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

# Clear enemy slots (remove enemy cards and discard them)
func clear_enemy_slots() -> void:
	if not enemy_deck:
		print("[TurnLogic] ERROR: Cannot discard cards - EnemyDeck not found")
		return
	
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var enemy_slots = []
	_find_enemy_slots(main_node, enemy_slots)
	
	var discard_slot = main_node.get_node_or_null("DiscardSlotEnemy")
	if not discard_slot:
		print("[TurnLogic] WARNING: DiscardSlotEnemy not found, cards will be removed but not visually placed")
	
	print("[TurnLogic] Discarding cards from ", enemy_slots.size(), " enemy slots")
	
	for slot in enemy_slots:
		# Check if game ended during discard
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[TurnLogic] Game ended during enemy slot discard, stopping")
				return
		
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card):
			# Get card data and add to discard pile
			if "card_data" in current_card and current_card.card_data:
				enemy_deck.discard_card(current_card.card_data)
				print("[TurnLogic] Discarded enemy card: ", current_card.card_data.card_name, " | Enemy discard size: ", enemy_deck.get_discard_size())
			
			# Remove card from slot FIRST to clear the slot reference
			if slot.has_method("remove_card"):
				slot.remove_card(current_card)
			# Also manually clear the slot's current_card reference as a safety measure
			if "current_card" in slot:
				slot.current_card = null
			
			# Move card to discard slot position if it exists
			if discard_slot:
				# Animate card to discard position
				var tween = get_tree().create_tween()
				tween.tween_property(current_card, "global_position", discard_slot.global_position, 0.3)
				await tween.finished
			
			# Remove the card node
			current_card.queue_free()
			await get_tree().process_frame
		else:
			# Even if no card, ensure slot is cleared
			if "current_card" in slot:
				slot.current_card = null

# Refill player hand to original amount (10 cards)
func refill_player_hand() -> void:
	# Check if game is still playing before doing anything
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game is over, skipping player hand refill")
			return
	
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
		# Check if game is still playing before drawing
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[TurnLogic] Game is over, stopping card draw")
				break
		
		var card_data = player_deck.draw_card()
		if not card_data:
			print("[TurnLogic] WARNING: Could not draw card ", i + 1, " - deck may be empty or game ended")
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
		new_card.set_meta("adding_to_hand", true)  # Prevent auto-snapping during hand refill
		
		# Disable Area2D monitoring during animation to prevent overlap detection
		var card_area = new_card.get_node_or_null("Area2D")
		if card_area:
			card_area.monitoring = false
		
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
		
		# Wait for animation to complete BEFORE adding to hand array
		await tween.finished
		
		# Now that card is in final position, add to hand array
		if "player_hand" in player_hand:
			player_hand.player_hand.append(new_card)
		
		# Update hand positions to ensure proper spacing
		if player_hand.has_method("update_hand_positions"):
			player_hand.update_hand_positions()
		
		# Small delay to ensure card is fully settled in hand position
		await get_tree().create_timer(0.05).timeout
		
		# Re-enable Area2D monitoring now that card is fully in hand and settled
		var player_card_area = new_card.get_node_or_null("Area2D")
		if player_card_area:
			player_card_area.monitoring = true
		
		# Remove the adding_to_hand flag now that card is fully in hand and settled
		if new_card.has_meta("adding_to_hand"):
			new_card.remove_meta("adding_to_hand")
		
		# Small delay between cards
		if i < cards_needed - 1:
			await get_tree().create_timer(0.05).timeout

# Refill enemy hand to original amount (10 cards)
func refill_enemy_hand() -> void:
	# Check if game is still playing before doing anything
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[TurnLogic] Game is over, skipping enemy hand refill")
			return
	
	if not enemy_hand or not enemy_deck:
		print("[TurnLogic] ERROR: Cannot refill enemy hand - missing references")
		return
	
	# Get current hand size
	var current_hand_size = 0
	if "enemy_hand" in enemy_hand:
		current_hand_size = enemy_hand.enemy_hand.size()
	
	var target_hand_size = 10  # HAND_COUNT
	var cards_needed = target_hand_size - current_hand_size
	
	if cards_needed <= 0:
		print("[TurnLogic] Enemy hand is already full (", current_hand_size, " cards)")
		return
	
	print("[TurnLogic] Drawing ", cards_needed, " cards to refill enemy hand")
	
	# Draw cards and add them to hand
	for i in range(cards_needed):
		# Check if game is still playing before drawing
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[TurnLogic] Game is over, stopping enemy card draw")
				break
		
		# Check if game ended before attempting to draw
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[TurnLogic] Game is over, stopping enemy card draw")
				break
		
		var card_data = enemy_deck.draw_card()
		if not card_data:
			print("[TurnLogic] WARNING: Could not draw card ", i + 1, " - deck may be empty or game ended")
			# Check if game ended due to empty deck - this should have been triggered in draw_card()
			if game_state and game_state.has_method("is_game_playing"):
				if not game_state.is_game_playing():
					print("[TurnLogic] Game ended due to enemy deck being empty - stopping refill")
				else:
					print("[TurnLogic] ERROR: draw_card() returned null but game is still playing! This shouldn't happen.")
			break
		
		# Create card instance
		var new_card = card_scene.instantiate()
		if not new_card:
			print("[TurnLogic] ERROR: Failed to instantiate card scene")
			continue
		
		# Get card number from EnemyHand
		var card_number = 1
		if "card_id_counter" in enemy_hand:
			card_number = enemy_hand.card_id_counter
			enemy_hand.card_id_counter += 1
		
		new_card.name = "EnemyCard" + str(card_number)
		
		# Set card number
		if new_card.has_method("set_card_number"):
			new_card.set_card_number(card_number)
		new_card.set_meta("card_number", card_number)
		new_card.set_meta("is_enemy_card", true)  # Mark as enemy card
		new_card.set_meta("adding_to_hand", true)  # Prevent auto-snapping during hand refill
		print("[TurnLogic] Created ", new_card.name, " - Set adding_to_hand flag")
		
		# Disable Area2D monitoring during animation to prevent overlap detection
		var card_area = new_card.get_node_or_null("Area2D")
		if card_area:
			card_area.monitoring = false
			print("[TurnLogic] Disabled monitoring for ", new_card.name, " | monitoring=", card_area.monitoring)
		else:
			print("[TurnLogic] ERROR: No Area2D found on ", new_card.name)
		
		# Set card data
		if new_card.has_method("set_card_data"):
			new_card.set_card_data(card_data)
		
		# Position card at deck location
		var deck_slot = get_parent().get_node_or_null("DeckSlotEnemy")
		if deck_slot:
			var deck_local_position = card_manager.to_local(deck_slot.global_position)
			new_card.position = deck_local_position
			print("[TurnLogic] Positioned ", new_card.name, " at deck location: ", deck_local_position)
		else:
			print("[TurnLogic] ERROR: DeckSlotEnemy not found!")
		
		# Add card to CardManager
		card_manager.add_child(new_card)
		print("[TurnLogic] Added ", new_card.name, " to CardManager tree")
		
		# Wait a frame to ensure card is in tree
		await get_tree().process_frame
		
		# Verify card is at deck position
		if deck_slot:
			var deck_local_position = card_manager.to_local(deck_slot.global_position)
			new_card.position = deck_local_position
			print("[TurnLogic] Verified ", new_card.name, " position after tree entry: ", new_card.global_position)
		
		# Set card data
		if new_card.has_method("set_card_data"):
			new_card.set_card_data(card_data)
			if new_card.has_method("update_card_display"):
				new_card.update_card_display()
		
		# Calculate target position in hand
		var current_hand_size_after_add = current_hand_size + i
		var target_x = 0.0
		if enemy_hand.has_method("calculate_card_position"):
			target_x = enemy_hand.calculate_card_position(current_hand_size_after_add)
		else:
			# Fallback calculation using constants
			var card_width = 100  # CARD_WIDTH constant
			var center_x = enemy_hand.center_screen_x if "center_screen_x" in enemy_hand else get_viewport().size.x / 2
			var total_width = (current_hand_size_after_add) * card_width
			target_x = center_x + current_hand_size_after_add * card_width - total_width / 2
		
		var hand_y = 110  # HAND_Y_POSITION constant for enemy
		var target_position = Vector2(target_x, hand_y)
		
		# Play flip animation and animate to hand position
		var animation_player = new_card.get_node_or_null("AnimationPlayer")
		if animation_player and animation_player.has_animation("card_flip"):
			animation_player.play("card_flip")
		
		# Animate to hand position
		print("[TurnLogic] Starting animation for ", new_card.name, " from ", new_card.global_position, " to ", target_position)
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(new_card, "position", target_position, 0.2)
		
		# Wait for animation to complete BEFORE adding to hand array
		await tween.finished
		print("[TurnLogic] Animation finished for ", new_card.name, " | Position: ", new_card.global_position)
		
		# Now that card is in final position, add to hand array
		if "enemy_hand" in enemy_hand:
			enemy_hand.enemy_hand.append(new_card)
			print("[TurnLogic] Added ", new_card.name, " to enemy hand array | Hand size: ", enemy_hand.enemy_hand.size())
		
		# Update hand positions to ensure proper spacing
		if enemy_hand.has_method("update_hand_positions"):
			enemy_hand.update_hand_positions()
		
		# Small delay to ensure card is fully settled in hand position
		await get_tree().create_timer(0.05).timeout
		
		# Re-enable Area2D monitoring now that card is fully in hand and settled
		var enemy_card_area = new_card.get_node_or_null("Area2D")
		if enemy_card_area:
			enemy_card_area.monitoring = true
			print("[TurnLogic] Re-enabled monitoring for ", new_card.name, " | monitoring=", enemy_card_area.monitoring)
		
		# Remove the adding_to_hand flag now that card is fully in hand and settled
		if new_card.has_meta("adding_to_hand"):
			new_card.remove_meta("adding_to_hand")
			print("[TurnLogic] Removed adding_to_hand flag from ", new_card.name)
		
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
