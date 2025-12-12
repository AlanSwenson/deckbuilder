extends Node
class_name HandRefiller

# References (set by TurnLogic)
var player_hand: Node2D = null
var enemy_hand: Node2D = null
var player_deck: Node2D = null
var enemy_deck: Node2D = null
var card_manager: Node2D = null
var game_state: Node2D = null
var card_scene: PackedScene = null

const CARD_SCENE_PATH = "res://scenes/Card.tscn"

func setup(player_hand_ref: Node2D, enemy_hand_ref: Node2D, player_deck_ref: Node2D, enemy_deck_ref: Node2D, card_manager_ref: Node2D, game_state_ref: Node2D) -> void:
	player_hand = player_hand_ref
	enemy_hand = enemy_hand_ref
	player_deck = player_deck_ref
	enemy_deck = enemy_deck_ref
	card_manager = card_manager_ref
	game_state = game_state_ref
	card_scene = preload(CARD_SCENE_PATH)

# Refill player hand to original amount (10 cards)
func refill_player_hand() -> void:
	# Check if game is still playing before doing anything
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[HandRefiller] Game is over, skipping player hand refill")
			return
	
	if not player_hand or not player_deck:
		print("[HandRefiller] ERROR: Cannot refill hand - missing references")
		return
	
	# Get current hand size
	var current_hand_size = 0
	if "player_hand" in player_hand:
		current_hand_size = player_hand.player_hand.size()
	
	var target_hand_size = 10  # HAND_COUNT
	var cards_needed = target_hand_size - current_hand_size
	
	if cards_needed <= 0:
		print("[HandRefiller] Hand is already full (", current_hand_size, " cards)")
		return
	
	print("[HandRefiller] Drawing ", cards_needed, " cards to refill hand")
	
	# Draw cards and add them to hand
	for i in range(cards_needed):
		# Check if game is still playing before drawing
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[HandRefiller] Game is over, stopping card draw")
				break
		
		var card_data = player_deck.draw_card()
		if not card_data:
			print("[HandRefiller] WARNING: Could not draw card ", i + 1, " - deck may be empty or game ended")
			break
		
		await _create_and_animate_card_to_hand(card_data, player_hand, player_deck, "Card", "DeckSlotPlayer", 890, current_hand_size + i)
		
		# Small delay between cards
		if i < cards_needed - 1:
			await get_tree().create_timer(0.05).timeout

# Refill enemy hand to original amount (10 cards)
func refill_enemy_hand() -> void:
	# Check if game is still playing before doing anything
	if game_state and game_state.has_method("is_game_playing"):
		if not game_state.is_game_playing():
			print("[HandRefiller] Game is over, skipping enemy hand refill")
			return
	
	if not enemy_hand or not enemy_deck:
		print("[HandRefiller] ERROR: Cannot refill enemy hand - missing references")
		return
	
	# Get current hand size
	var current_hand_size = 0
	if "enemy_hand" in enemy_hand:
		current_hand_size = enemy_hand.enemy_hand.size()
	
	var target_hand_size = 10  # HAND_COUNT
	var cards_needed = target_hand_size - current_hand_size
	
	if cards_needed <= 0:
		print("[HandRefiller] Enemy hand is already full (", current_hand_size, " cards)")
		return
	
	print("[HandRefiller] Drawing ", cards_needed, " cards to refill enemy hand")
	
	# Draw cards and add them to hand
	for i in range(cards_needed):
		# Check if game is still playing before drawing
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[HandRefiller] Game is over, stopping enemy card draw")
				break
		
		var card_data = enemy_deck.draw_card()
		if not card_data:
			print("[HandRefiller] WARNING: Could not draw card ", i + 1, " - deck may be empty or game ended")
			if game_state and game_state.has_method("is_game_playing"):
				if not game_state.is_game_playing():
					print("[HandRefiller] Game ended due to enemy deck being empty - stopping refill")
			break
		
		await _create_and_animate_card_to_hand(card_data, enemy_hand, enemy_deck, "EnemyCard", "DeckSlotEnemy", 110, current_hand_size + i, true)
		
		# Small delay between cards
		if i < cards_needed - 1:
			await get_tree().create_timer(0.05).timeout

# Helper function to create and animate a card to hand
func _create_and_animate_card_to_hand(card_data, hand: Node2D, deck: Node2D, card_name_prefix: String, deck_slot_name: String, hand_y: float, hand_index: int, is_enemy: bool = false) -> void:
	# Create card instance
	var new_card = card_scene.instantiate()
	if not new_card:
		print("[HandRefiller] ERROR: Failed to instantiate card scene")
		return
	
	# Get card number from hand
	var card_number = 1
	if "card_id_counter" in hand:
		card_number = hand.card_id_counter
		hand.card_id_counter += 1
	
	new_card.name = card_name_prefix + str(card_number)
	
	# Set card number
	if new_card.has_method("set_card_number"):
		new_card.set_card_number(card_number)
	new_card.set_meta("card_number", card_number)
	if is_enemy:
		new_card.set_meta("is_enemy_card", true)
	new_card.set_meta("adding_to_hand", true)  # Prevent auto-snapping during hand refill
	
	# Disable Area2D monitoring during animation to prevent overlap detection
	var card_area = new_card.get_node_or_null("Area2D")
	if card_area:
		card_area.monitoring = false
		if is_enemy:
			print("[HandRefiller] Disabled monitoring for ", new_card.name, " | monitoring=", card_area.monitoring)
	else:
		if is_enemy:
			print("[HandRefiller] ERROR: No Area2D found on ", new_card.name)
	
	# Set card data
	if new_card.has_method("set_card_data"):
		new_card.set_card_data(card_data)
	
	# Position card at deck location
	var main_node = get_tree().current_scene
	var deck_slot = main_node.get_node_or_null(deck_slot_name)
	if deck_slot:
		var deck_local_position = card_manager.to_local(deck_slot.global_position)
		new_card.position = deck_local_position
		if is_enemy:
			print("[HandRefiller] Positioned ", new_card.name, " at deck location: ", deck_local_position)
	else:
		if is_enemy:
			print("[HandRefiller] ERROR: ", deck_slot_name, " not found!")
	
	# Add card to CardManager
	card_manager.add_child(new_card)
	if is_enemy:
		print("[HandRefiller] Added ", new_card.name, " to CardManager tree")
	
	# Wait a frame to ensure card is in tree
	await get_tree().process_frame
	
	# Verify card is at deck position
	if deck_slot:
		var deck_local_position = card_manager.to_local(deck_slot.global_position)
		new_card.position = deck_local_position
		if is_enemy:
			print("[HandRefiller] Verified ", new_card.name, " position after tree entry: ", new_card.global_position)
	
	# Set card data
	if new_card.has_method("set_card_data"):
		new_card.set_card_data(card_data)
		if new_card.has_method("update_card_display"):
			new_card.update_card_display()
	
	# Calculate target position in hand
	var target_x = 0.0
	if hand.has_method("calculate_card_position"):
		target_x = hand.calculate_card_position(hand_index)
	else:
		# Fallback calculation using constants
		var card_width = 100  # CARD_WIDTH constant
		var center_x = hand.center_screen_x if "center_screen_x" in hand else get_viewport().size.x / 2
		var total_width = hand_index * card_width
		target_x = center_x + hand_index * card_width - total_width / 2
	
	var target_position = Vector2(target_x, hand_y)
	
	# Play flip animation and animate to hand position
	var animation_player = new_card.get_node_or_null("AnimationPlayer")
	if animation_player and animation_player.has_animation("card_flip"):
		animation_player.play("card_flip")
	
	# Animate to hand position
	if is_enemy:
		print("[HandRefiller] Starting animation for ", new_card.name, " from ", new_card.global_position, " to ", target_position)
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(new_card, "position", target_position, 0.2)
	
	# Wait for animation to complete BEFORE adding to hand array
	await tween.finished
	if is_enemy:
		print("[HandRefiller] Animation finished for ", new_card.name, " | Position: ", new_card.global_position)
	
	# Now that card is in final position, add to hand array
	if is_enemy and "enemy_hand" in hand:
		hand.enemy_hand.append(new_card)
		print("[HandRefiller] Added ", new_card.name, " to enemy hand array | Hand size: ", hand.enemy_hand.size())
	elif not is_enemy and "player_hand" in hand:
		hand.player_hand.append(new_card)
	
	# Update hand positions to ensure proper spacing
	if hand.has_method("update_hand_positions"):
		hand.update_hand_positions()
	
	# Small delay to ensure card is fully settled in hand position
	await get_tree().create_timer(0.05).timeout
	
	# Re-enable Area2D monitoring now that card is fully in hand and settled
	var card_area_final = new_card.get_node_or_null("Area2D")
	if card_area_final:
		card_area_final.monitoring = true
		if is_enemy:
			print("[HandRefiller] Re-enabled monitoring for ", new_card.name, " | monitoring=", card_area_final.monitoring)
	
	# Remove the adding_to_hand flag now that card is fully in hand and settled
	if new_card.has_meta("adding_to_hand"):
		new_card.remove_meta("adding_to_hand")
		if is_enemy:
			print("[HandRefiller] Removed adding_to_hand flag from ", new_card.name)

