extends Node2D

const CARD_SCENE_PATH = "res://scenes/Card.tscn"

var card_manager: Node2D = null
var enemy_deck: Node2D = null
var card_scene: PackedScene = null

func _ready() -> void:
	# Load card scene
	card_scene = preload(CARD_SCENE_PATH)
	
	# Find references
	card_manager = get_parent().get_node_or_null("CardManager")
	enemy_deck = get_parent().get_node_or_null("EnemyDeck")
	
	if not card_manager:
		print("[TurnLogic] ERROR: CardManager not found")
	if not enemy_deck:
		print("[TurnLogic] ERROR: EnemyDeck not found")
	
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
	
	# TODO: Evaluate player cards in player slots
	# TODO: Resolve turn (damage, healing, etc.)
	# TODO: Clean up and prepare for next turn

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

# Recursively find all enemy slots
func _find_enemy_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("EnemySlot"):
		result.append(node)
	
	for child in node.get_children():
		_find_enemy_slots(child, result)
