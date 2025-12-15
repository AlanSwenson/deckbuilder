extends Node
class_name GameStateSaver

# Utility class for saving and loading complete game state
# Used for autosave/crash recovery

# Helper function to flip a card face-up (for loading saved state)
# This directly seeks the animation to the end to show the card face-up
func flip_card_face_up(card_node: Node2D) -> void:
	if not card_node or not is_instance_valid(card_node):
		return
	
	# Wait a frame to ensure card is fully initialized
	await get_tree().process_frame
	
	var animation_player = card_node.get_node_or_null("AnimationPlayer")
	if animation_player:
		# If the animation exists, seek to the end to show face-up state
		if animation_player.has_animation("card_flip"):
			# Play the animation and seek to the end immediately
			animation_player.play("card_flip")
			var anim = animation_player.get_animation("card_flip")
			if anim:
				animation_player.seek(anim.length)
				animation_player.advance(0)  # Force update
		else:
			print("[GameStateSaver] No card_flip animation found, card may remain as back")
	else:
		print("[GameStateSaver] No AnimationPlayer found on card, card may remain as back")

# Save the entire current game state to SaveData
func save_game_state(save_data: SaveData) -> void:
	if not save_data:
		push_error("[GameStateSaver] No save_data provided")
		return
	
	var main_node = get_tree().current_scene if is_inside_tree() else null
	if not main_node:
		# Try alternative method
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			main_node = scene_tree.current_scene
	if not main_node:
		push_error("[GameStateSaver] No current scene found")
		return
	
	# Get all game state components
	var game_state = main_node.get_node_or_null("GameState")
	var player_hand = main_node.get_node_or_null("PlayerHand")
	var enemy_hand = main_node.get_node_or_null("EnemyHand")
	var player_deck = main_node.get_node_or_null("PlayerDeck")
	var enemy_deck = main_node.get_node_or_null("EnemyDeck")
	
	if not game_state:
		push_error("[GameStateSaver] GameState not found")
		return
	
	# Save HP and game status
	save_data.match_player_hp = game_state.player_hp
	save_data.match_enemy_hp = game_state.enemy_hp
	save_data.match_game_status = game_state.game_status
	
	# Save player hand
	save_data.match_player_hand.clear()
	if player_hand and "player_hand" in player_hand:
		for card_node in player_hand.player_hand:
			if card_node and is_instance_valid(card_node) and "card_data" in card_node:
				var card_data = card_node.card_data
				if card_data:
					save_data.match_player_hand.append(card_data.to_save_dict())
	
	# Save enemy hand
	save_data.match_enemy_hand.clear()
	if enemy_hand and "enemy_hand" in enemy_hand:
		for card_node in enemy_hand.enemy_hand:
			if card_node and is_instance_valid(card_node) and "card_data" in card_node:
				var card_data = card_node.card_data
				if card_data:
					save_data.match_enemy_hand.append(card_data.to_save_dict())
	
	# Save player deck
	save_data.match_player_deck.clear()
	if player_deck and "deck" in player_deck:
		for card_data in player_deck.deck:
			if card_data:
				save_data.match_player_deck.append(card_data.to_save_dict())
	
	# Save enemy deck
	save_data.match_enemy_deck.clear()
	if enemy_deck and "deck" in enemy_deck:
		for card_data in enemy_deck.deck:
			if card_data:
				save_data.match_enemy_deck.append(card_data.to_save_dict())
	
	# Save discard piles
	save_data.match_player_discard.clear()
	if player_deck and "discard_pile" in player_deck:
		for card_data in player_deck.discard_pile:
			if card_data:
				save_data.match_player_discard.append(card_data.to_save_dict())
	
	save_data.match_enemy_discard.clear()
	if enemy_deck and "discard_pile" in enemy_deck:
		for card_data in enemy_deck.discard_pile:
			if card_data:
				save_data.match_enemy_discard.append(card_data.to_save_dict())
	
	# Save cards in play slots
	save_data.match_player_slots.clear()
	save_data.match_enemy_slots.clear()
	for i in range(1, 6):  # Slots 1-5
		var player_slot = main_node.get_node_or_null("PlayerSlot%d" % i)
		var enemy_slot = main_node.get_node_or_null("EnemySlot%d" % i)
		
		if player_slot:
			var card = null
			if "current_card" in player_slot:
				card = player_slot.current_card
			elif player_slot.has_method("get_current_card"):
				card = player_slot.get_current_card()
			
			if card and is_instance_valid(card) and "card_data" in card:
				save_data.match_player_slots.append(card.card_data.to_save_dict())
			else:
				save_data.match_player_slots.append({})  # Empty slot
		
		if enemy_slot:
			var card = null
			if "current_card" in enemy_slot:
				card = enemy_slot.current_card
			elif enemy_slot.has_method("get_current_card"):
				card = enemy_slot.get_current_card()
			
			if card and is_instance_valid(card) and "card_data" in card:
				save_data.match_enemy_slots.append(card.card_data.to_save_dict())
			else:
				save_data.match_enemy_slots.append({})  # Empty slot
	
	save_data.has_active_match = true
	print("[GameStateSaver] Saved complete game state")

# Load the entire game state from SaveData
# Note: This should be called after the scene is fully loaded
func load_game_state(save_data: SaveData) -> bool:
	if not save_data or not save_data.has_active_match:
		print("[GameStateSaver] No active match to load")
		return false
	
	var main_node = get_tree().current_scene if is_inside_tree() else null
	if not main_node:
		# Try alternative method
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			main_node = scene_tree.current_scene
	if not main_node:
		push_error("[GameStateSaver] No current scene found")
		return false
	
	# Get all game state components
	var game_state = main_node.get_node_or_null("GameState")
	var player_hand = main_node.get_node_or_null("PlayerHand")
	var enemy_hand = main_node.get_node_or_null("EnemyHand")
	var player_deck = main_node.get_node_or_null("PlayerDeck")
	var enemy_deck = main_node.get_node_or_null("EnemyDeck")
	var card_manager = main_node.get_node_or_null("CardManager")
	
	if not game_state:
		push_error("[GameStateSaver] GameState not found")
		return false
	
	# Restore HP and game status
	game_state.player_hp = save_data.match_player_hp
	game_state.enemy_hp = save_data.match_enemy_hp
	game_state.game_status = save_data.match_game_status
	game_state.update_hp_display()
	
	# Restore player deck
	if player_deck and "deck" in player_deck:
		player_deck.deck.clear()
		for card_dict in save_data.match_player_deck:
			var card_data = CardData.from_save_dict(card_dict)
			player_deck.deck.append(card_data)
	
	# Restore enemy deck
	if enemy_deck and "deck" in enemy_deck:
		enemy_deck.deck.clear()
		for card_dict in save_data.match_enemy_deck:
			var card_data = CardData.from_save_dict(card_dict)
			enemy_deck.deck.append(card_data)
	
	# Restore discard piles
	if player_deck and "discard_pile" in player_deck:
		player_deck.discard_pile.clear()
		for card_dict in save_data.match_player_discard:
			var card_data = CardData.from_save_dict(card_dict)
			player_deck.discard_pile.append(card_data)
	
	if enemy_deck and "discard_pile" in enemy_deck:
		enemy_deck.discard_pile.clear()
		for card_dict in save_data.match_enemy_discard:
			var card_data = CardData.from_save_dict(card_dict)
			enemy_deck.discard_pile.append(card_data)
	
	# Helper function to create a card node from CardData
	var card_scene = preload("res://scenes/Card.tscn")
	
	# Restore player hand (create card nodes)
	if player_hand and "player_hand" in player_hand:
		# Clear existing hand
		for card_node in player_hand.player_hand.duplicate():
			if card_node and is_instance_valid(card_node):
				card_node.queue_free()
		player_hand.player_hand.clear()
		
		# Create cards from saved data
		for i in range(save_data.match_player_hand.size()):
			var card_dict = save_data.match_player_hand[i]
			if card_dict.is_empty():
				continue
			
			var card_data = CardData.from_save_dict(card_dict)
			var card_node = card_scene.instantiate()
			card_node.name = "Card%d" % (i + 1)
			card_node.set_card_number(i + 1)
			card_node.set_meta("card_number", i + 1)
			
			# Add to CardManager
			if card_manager:
				card_manager.add_child(card_node)
				# Wait a frame for card to be in tree
				await get_tree().process_frame
				card_node.set_card_data(card_data)
				card_manager.register_card(card_node)
				
				# Flip card face-up since we're loading a saved state
				await flip_card_face_up(card_node)
			
			player_hand.player_hand.append(card_node)
	
	# Restore enemy hand
	if enemy_hand and "enemy_hand" in enemy_hand:
		# Clear existing hand
		for card_node in enemy_hand.enemy_hand.duplicate():
			if card_node and is_instance_valid(card_node):
				card_node.queue_free()
		enemy_hand.enemy_hand.clear()
		
		# Create cards from saved data
		for i in range(save_data.match_enemy_hand.size()):
			var card_dict = save_data.match_enemy_hand[i]
			if card_dict.is_empty():
				continue
			
			var card_data = CardData.from_save_dict(card_dict)
			var card_node = card_scene.instantiate()
			card_node.name = "EnemyCard%d" % (i + 1)
			card_node.set_card_number(i + 1)
			card_node.set_meta("card_number", i + 1)
			
			# Add to CardManager
			if card_manager:
				card_manager.add_child(card_node)
				# Wait a frame for card to be in tree
				await get_tree().process_frame
				card_node.set_card_data(card_data)
				card_manager.register_card(card_node)
				
				# Flip card face-up since we're loading a saved state
				await flip_card_face_up(card_node)
			
			enemy_hand.enemy_hand.append(card_node)
	
	# Restore cards in play slots
	for i in range(mini(5, save_data.match_player_slots.size())):
		var slot_num = i + 1
		var player_slot = main_node.get_node_or_null("PlayerSlot%d" % slot_num)
		if player_slot:
			var card_dict = save_data.match_player_slots[i]
			if not card_dict.is_empty():
				var card_data = CardData.from_save_dict(card_dict)
				var card_node = card_scene.instantiate()
				card_node.name = "CardSlot%d" % slot_num
				
				if card_manager:
					card_manager.add_child(card_node)
					# Wait a frame for card to be in tree
					await get_tree().process_frame
					card_node.set_card_data(card_data)
					card_manager.register_card(card_node)
					
					# Flip card face-up since we're loading a saved state
					await flip_card_face_up(card_node)
					
					if player_slot.has_method("snap_card"):
						player_slot.snap_card(card_node)
	
	for i in range(mini(5, save_data.match_enemy_slots.size())):
		var slot_num = i + 1
		var enemy_slot = main_node.get_node_or_null("EnemySlot%d" % slot_num)
		if enemy_slot:
			var card_dict = save_data.match_enemy_slots[i]
			if not card_dict.is_empty():
				var card_data = CardData.from_save_dict(card_dict)
				var card_node = card_scene.instantiate()
				card_node.name = "EnemyCardSlot%d" % slot_num
				
				if card_manager:
					card_manager.add_child(card_node)
					# Wait a frame for card to be in tree
					await get_tree().process_frame
					card_node.set_card_data(card_data)
					card_manager.register_card(card_node)
					
					# Flip card face-up since we're loading a saved state
					await flip_card_face_up(card_node)
					
					if enemy_slot.has_method("snap_card"):
						enemy_slot.snap_card(card_node)
	
	# Update hand positions after loading cards
	if player_hand and player_hand.has_method("update_hand_positions"):
		player_hand.update_hand_positions()
	
	if enemy_hand and enemy_hand.has_method("update_hand_positions"):
		enemy_hand.update_hand_positions()
	
	print("[GameStateSaver] Loaded complete game state")
	return true
