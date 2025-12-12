extends Node
class_name CardDiscarder

# References (set by TurnLogic)
var player_deck: Node2D = null
var enemy_deck: Node2D = null
var game_state: Node2D = null

func setup(player_deck_ref: Node2D, enemy_deck_ref: Node2D, game_state_ref: Node2D) -> void:
	player_deck = player_deck_ref
	enemy_deck = enemy_deck_ref
	game_state = game_state_ref

# Move all cards from player slots to discard slot
func discard_player_slot_cards() -> void:
	if not player_deck:
		print("[CardDiscarder] ERROR: Cannot discard cards - PlayerDeck not found")
		return
	
	var main_node = get_tree().current_scene
	var player_slots = []
	_find_player_slots(main_node, player_slots)
	
	var discard_slot = main_node.get_node_or_null("DiscardSlotPlayer")
	if not discard_slot:
		print("[CardDiscarder] WARNING: DiscardSlotPlayer not found, cards will be removed but not visually placed")
	
	print("[CardDiscarder] Discarding cards from ", player_slots.size(), " player slots")
	
	for slot in player_slots:
		# Check if game ended during discard
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[CardDiscarder] Game ended during player slot discard, stopping")
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
				print("[CardDiscarder] Discarded card: ", current_card.card_data.card_name)
			
			# Remove card from slot
			if slot.has_method("remove_card"):
				slot.remove_card(current_card)
			
			# Move card to discard slot position if it exists
			if discard_slot:
				var tween = get_tree().create_tween()
				tween.tween_property(current_card, "global_position", discard_slot.global_position, 0.3)
				await tween.finished
			
			# Remove the card node
			current_card.queue_free()
			await get_tree().process_frame

# Clear enemy slots (remove enemy cards and discard them)
func clear_enemy_slots() -> void:
	if not enemy_deck:
		print("[CardDiscarder] ERROR: Cannot discard cards - EnemyDeck not found")
		return
	
	var main_node = get_tree().current_scene
	var enemy_slots = []
	_find_enemy_slots(main_node, enemy_slots)
	
	var discard_slot = main_node.get_node_or_null("DiscardSlotEnemy")
	if not discard_slot:
		print("[CardDiscarder] WARNING: DiscardSlotEnemy not found, cards will be removed but not visually placed")
	
	print("[CardDiscarder] Discarding cards from ", enemy_slots.size(), " enemy slots")
	
	for slot in enemy_slots:
		# Check if game ended during discard
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[CardDiscarder] Game ended during enemy slot discard, stopping")
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
				print("[CardDiscarder] Discarded enemy card: ", current_card.card_data.card_name, " | Enemy discard size: ", enemy_deck.get_discard_size())
			
			# Remove card from slot FIRST to clear the slot reference
			if slot.has_method("remove_card"):
				slot.remove_card(current_card)
			# Also manually clear the slot's current_card reference as a safety measure
			if "current_card" in slot:
				slot.current_card = null
			
			# Move card to discard slot position if it exists
			if discard_slot:
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

# Recursively find all player slots
func _find_player_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("PlayerSlot"):
		result.append(node)
	
	for child in node.get_children():
		_find_player_slots(child, result)

# Recursively find all enemy slots
func _find_enemy_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("EnemySlot"):
		result.append(node)
	
	for child in node.get_children():
		_find_enemy_slots(child, result)

