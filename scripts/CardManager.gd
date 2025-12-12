extends Node2D

# Reference to InputManager
var input_manager: Node2D = null

# Card slot configuration
const CARD_SLOT_COUNT: int = 5
const CARD_SLOT_SCENE_PATH: String = "res://scenes/CardSlot.tscn"
const CARD_SLOT_START_X: float = 400.0  # Starting X position for first slot
const PLAYER_SLOT_Y: float = 600.0  # Y position for player slots (closer to player hand)
const ENEMY_SLOT_Y: float = 350.0  # Y position for enemy slots (at top)
const CARD_SLOT_SPACING: float = 170.0  # Horizontal spacing between slots

@onready var deck_view = $"../DeckView"
@onready var view_deck_button = $"../ViewDeckButton"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find InputManager
	input_manager = get_node_or_null("../InputManager")
	if not input_manager:
		input_manager = get_tree().current_scene.get_node_or_null("InputManager")

	# Instantiate player and enemy card slots
	_create_player_slots()
	_create_enemy_slots()

	# Connect to child_added signal to handle dynamically added cards
	child_entered_tree.connect(_on_child_added)

	# Find all card nodes (they all start with "Card" or "EnemyCard")
	var card_nodes = []
	for child in get_children():
		if child.name.begins_with("Card") or child.name.begins_with("EnemyCard"):
			card_nodes.append(child)

	print("[CardManager] _ready() - Found ", card_nodes.size(), " card(s)")

	# Connect to each card's Area2D
	for card in card_nodes:
		_connect_card(card)
		
	view_deck_button.pressed.connect(_on_view_deck_pressed)

func _on_view_deck_pressed():
	deck_view.open()
# Public function to register a card (can be called from other scripts)
func register_card(card: Node2D) -> void:
	_connect_card(card)

# Connect a card to the input system
func _connect_card(card: Node2D) -> void:
	if not card or not is_instance_valid(card):
		return
	
	# Wait a frame if the card was just added to ensure it's fully initialized
	if not card.is_inside_tree():
		await card.tree_entered
	
	var card_area = card.get_node_or_null("Area2D")
	if card_area:
		# Ensure the Area2D can receive input
		card_area.input_pickable = true
		
		# Connect to InputManager for input handling
		if input_manager:
			# Connect to the input_event signal - forward to InputManager
			card_area.input_event.connect(
				func(viewport: Node, event: InputEvent, shape_idx: int):
					input_manager._on_card_input_event(card, viewport, event, shape_idx)
			)
			
			# Connect mouse enter/exit signals for hover effects - forward to InputManager
			card_area.mouse_entered.connect(
				func(): input_manager._on_card_mouse_entered(card)
			)
			card_area.mouse_exited.connect(
				func(): input_manager._on_card_mouse_exited(card)
			)
		
		print("[CardManager] Connected to Area2D for card: ", card.name)
	else:
		print("[CardManager] ERROR - Area2D not found for card: ", card.name)

# Called when a child node is added to CardManager
func _on_child_added(node: Node) -> void:
	# Check if it's a card (starts with "Card")
	if node.name.begins_with("Card"):
		# Wait a frame to ensure the node is fully initialized
		await get_tree().process_frame
		_connect_card(node)

# Find which slot (if any) a card is currently in
func find_card_slot(card: Node2D) -> Node2D:
	if not card:
		return null
	
	if card.has_meta("current_slot"):
		return card.get_meta("current_slot")
	
	# Fallback: search all slots for this card
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var card_slots = []
	_find_card_slots(main_node, card_slots)
	
	for slot in card_slots:
		if slot.has_method("get_current_card"):
			if slot.get_current_card() == card:
				return slot
	
	return null

# Check if a card overlaps any CardSlot and snap it if it does
# Returns true if the card was snapped to a slot, false otherwise
func check_and_snap_to_slot(card: Node2D) -> bool:
	if not card:
		return false
	
	# Find the slot this card originally came from (if any)
	var original_slot = find_card_slot(card)
	
	# Find all CardSlot nodes in the scene
	# (they should be siblings of CardManager or in parent)
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var card_slots = []
	_find_card_slots(main_node, card_slots)
	
	# Check if this is a player card or enemy card
	var is_player_card = false
	var is_enemy_card = false
	var player_hand = main_node.get_node_or_null("PlayerHand")
	var enemy_hand = main_node.get_node_or_null("EnemyHand")
	
	# Check if card is in player hand
	if player_hand and player_hand.has_method("is_card_in_hand"):
		is_player_card = player_hand.is_card_in_hand(card)
	
	# Check if card is in enemy hand
	if not is_player_card and enemy_hand and enemy_hand.has_method("is_card_in_hand"):
		is_enemy_card = enemy_hand.is_card_in_hand(card)
	
	# Check if card has enemy meta flag
	if not is_player_card and not is_enemy_card:
		if card.has_meta("is_enemy_card"):
			is_enemy_card = card.get_meta("is_enemy_card")
	
	# Also check if card came from a slot
	if not is_player_card and not is_enemy_card and original_slot:
		if original_slot.name.begins_with("PlayerSlot"):
			is_player_card = true
		elif original_slot.name.begins_with("EnemySlot"):
			is_enemy_card = true
	
	# Find all slots that overlap with the card
	var overlapping_slots = []
	for slot in card_slots:
		if slot.has_method("is_card_overlapping"):
			if slot.is_card_overlapping(card):
				# Player cards can only go to player slots, enemy cards to enemy slots
				if is_player_card and slot.name.begins_with("EnemySlot"):
					continue  # Skip enemy slots for player cards
				if is_enemy_card and slot.name.begins_with("PlayerSlot"):
					continue  # Skip player slots for enemy cards
				overlapping_slots.append(slot)
	
	# If no overlapping slots, clear the card's slot reference if it had one
	if overlapping_slots.is_empty():
		if original_slot and original_slot.has_method("remove_card"):
			original_slot.remove_card(card)
		return false
	
	# Determine target slot (closest if multiple)
	var target_slot = null
	
	if overlapping_slots.size() == 1:
		target_slot = overlapping_slots[0]
	else:
		# Multiple overlapping slots - find the one closest to mouse position
		var mouse_pos = get_global_mouse_position()
		var closest_distance = INF
		
		for slot in overlapping_slots:
			if slot.has_method("get_distance_to_point"):
				var distance = slot.get_distance_to_point(mouse_pos)
				if distance < closest_distance:
					closest_distance = distance
					target_slot = slot
			else:
				# Fallback: use distance from global_position
				var distance = slot.global_position.distance_to(mouse_pos)
				if distance < closest_distance:
					closest_distance = distance
					target_slot = slot
	
	# Snap to the target slot (this will handle swapping automatically)
	if target_slot and target_slot.has_method("snap_card"):
		# Safety check: prevent player cards from going to enemy slots and vice versa
		if is_player_card and target_slot.name.begins_with("EnemySlot"):
			print("[CardManager] Player cards cannot be placed in enemy slots!")
			return false
		if is_enemy_card and target_slot.name.begins_with("PlayerSlot"):
			print("[CardManager] Enemy cards cannot be placed in player slots!")
			return false
		
		# If card was in a different slot, remove it from that slot first
		if original_slot and original_slot != target_slot:
			if original_slot.has_method("remove_card"):
				original_slot.remove_card(card)
		
		# Snap the card (swaps if slot is occupied)
		var swapped_card = target_slot.snap_card(card)
		
		# Ensure the card that was just snapped is properly set in the slot
		# and NOT in hand
		if card:
			if is_player_card and player_hand and player_hand.has_method("remove_card_from_hand"):
				# Remove from player hand if it was there (will be no-op if not in hand)
				player_hand.remove_card_from_hand(card)
			elif is_enemy_card and enemy_hand and enemy_hand.has_method("remove_card_from_hand"):
				# Remove from enemy hand if it was there (will be no-op if not in hand)
				enemy_hand.remove_card_from_hand(card)
		
		# Handle the swapped card
		if swapped_card and swapped_card != card:
			# The swapped card needs to go somewhere
			# If the original card was from hand, send swapped card to hand
			# If the original card was from another slot, swapped card goes there
			if original_slot and original_slot.has_method("snap_card"):
				# Card was moved from one slot to another - swap positions
				original_slot.snap_card(swapped_card)
				# Update starting position for the swapped card
				swapped_card.set_meta("starting_position", original_slot.global_position)
			else:
				# Card was from hand - send swapped card back to hand
				# The swapped card's slot reference was already cleared by snap_card
				# Just add it to hand
				if is_player_card and player_hand and player_hand.has_method("add_card_to_hand_at_index"):
					# Make sure it's not already in hand
					if not player_hand.has_method("is_card_in_hand") or not player_hand.is_card_in_hand(swapped_card):
						# Use mouse position to calculate hand index for better placement
						var mouse_pos = get_global_mouse_position()
						var target_index = 0
						if player_hand.has_method("calculate_index_from_x"):
							target_index = player_hand.calculate_index_from_x(mouse_pos.x)
						player_hand.add_card_to_hand_at_index(swapped_card, target_index)
					# Update starting position will be set when hand positions update
				elif is_enemy_card and enemy_hand and enemy_hand.has_method("add_card_to_hand_at_index"):
					# Make sure it's not already in hand
					if not enemy_hand.has_method("is_card_in_hand") or not enemy_hand.is_card_in_hand(swapped_card):
						# Use mouse position to calculate hand index for better placement
						var mouse_pos = get_global_mouse_position()
						var target_index = 0
						if enemy_hand.has_method("calculate_index_from_x"):
							target_index = enemy_hand.calculate_index_from_x(mouse_pos.x)
						enemy_hand.add_card_to_hand_at_index(swapped_card, target_index)
					# Update starting position will be set when hand positions update
		
		# Update starting position for the card that was snapped
		card.set_meta("starting_position", target_slot.global_position)
		
		print(
			"[CardManager] Card snapped to slot: ",
			target_slot.name,
			" (swapped: ",
			swapped_card != null and swapped_card != card,
			")"
		)
		return true
	
	return false

# Recursively find all CardSlot nodes in the scene tree
func _find_card_slots(node: Node, result: Array) -> void:
	# Check if this node is a CardSlot by name or by script
	var is_card_slot = node.name.begins_with("CardSlot") or node.name.begins_with("PlayerSlot") or node.name.begins_with("EnemySlot")
	var has_snap_method = (
		node.get_script() and node.has_method("snap_card")
	)
	if is_card_slot or has_snap_method:
		result.append(node)
	
	for child in node.get_children():
		_find_card_slots(child, result)

# Create and position player card slots
func _create_player_slots() -> void:
	# Wait a frame to ensure viewport is ready
	await get_tree().process_frame
	
	var card_slot_scene = preload(CARD_SLOT_SCENE_PATH)
	if not card_slot_scene:
		print("[CardManager] ERROR: Could not load CardSlot scene")
		return
	
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	if not main_node:
		print("[CardManager] ERROR: Could not find main node")
		return
	
	# Calculate center position to center the slots
	var viewport_size = get_viewport().get_visible_rect().size
	# Fallback if viewport size is not available yet
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		viewport_size = Vector2(1600, 1000)  # Default viewport size
		print("[CardManager] Using fallback viewport size: ", viewport_size)
	else:
		print("[CardManager] Viewport size: ", viewport_size)
	
	var total_width = (CARD_SLOT_COUNT - 1) * CARD_SLOT_SPACING
	var start_x = viewport_size.x / 2 - total_width / 2
	print("[CardManager] Calculated start_x: ", start_x, " for ", CARD_SLOT_COUNT, " player slots")
	
	# Create 5 player card slots
	for i in range(CARD_SLOT_COUNT):
		var slot = card_slot_scene.instantiate()
		slot.name = "PlayerSlot" + str(i + 1)
		
		# Position slots horizontally, centered on screen, closer to player
		var x_position = start_x + (i * CARD_SLOT_SPACING)
		slot.position = Vector2(x_position, PLAYER_SLOT_Y)
		slot.z_index = -1
		
		# Add slot to main scene (as sibling of CardManager)
		main_node.add_child(slot)
		print(
			"[CardManager] Created player slot: ",
			slot.name,
			" at position: ",
			slot.position,
			" (global: ",
			slot.global_position,
			")"
		)
		
		# Verify the sprite exists and is visible
		var sprite = slot.get_node_or_null("CardSlotImage")
		if sprite:
			print(
				"[CardManager] Player slot ",
				slot.name,
				" has sprite at position: ",
				sprite.position
			)
		else:
			print("[CardManager] WARNING: Player slot ", slot.name, " missing CardSlotImage!")

# Create and position enemy card slots
func _create_enemy_slots() -> void:
	# Wait a frame to ensure viewport is ready
	await get_tree().process_frame
	
	var card_slot_scene = preload(CARD_SLOT_SCENE_PATH)
	if not card_slot_scene:
		print("[CardManager] ERROR: Could not load CardSlot scene")
		return
	
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	if not main_node:
		print("[CardManager] ERROR: Could not find main node")
		return
	
	# Calculate center position to center the slots
	var viewport_size = get_viewport().get_visible_rect().size
	# Fallback if viewport size is not available yet
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		viewport_size = Vector2(1600, 1000)  # Default viewport size
		print("[CardManager] Using fallback viewport size: ", viewport_size)
	else:
		print("[CardManager] Viewport size: ", viewport_size)
	
	var total_width = (CARD_SLOT_COUNT - 1) * CARD_SLOT_SPACING
	var start_x = viewport_size.x / 2 - total_width / 2
	print("[CardManager] Calculated start_x: ", start_x, " for ", CARD_SLOT_COUNT, " enemy slots")
	
	# Create 5 enemy card slots
	for i in range(CARD_SLOT_COUNT):
		var slot = card_slot_scene.instantiate()
		slot.name = "EnemySlot" + str(i + 1)
		
		# Position slots horizontally, centered on screen, at top for enemy
		var x_position = start_x + (i * CARD_SLOT_SPACING)
		slot.position = Vector2(x_position, ENEMY_SLOT_Y)
		slot.z_index = -1
		
		# Add slot to main scene (as sibling of CardManager)
		main_node.add_child(slot)
		print(
			"[CardManager] Created enemy slot: ",
			slot.name,
			" at position: ",
			slot.position,
			" (global: ",
			slot.global_position,
			")"
		)
		
		# Verify the sprite exists and is visible
		var sprite = slot.get_node_or_null("CardSlotImage")
		if sprite:
			print(
				"[CardManager] Enemy slot ",
				slot.name,
				" has sprite at position: ",
				sprite.position
			)
		else:
			print("[CardManager] WARNING: Enemy slot ", slot.name, " missing CardSlotImage!")

# Notify PlayerHand that a card was played (snapped to a slot)
func notify_card_played(card: Node2D) -> void:
	if not card:
		return
	
	# Find PlayerHand node (sibling of CardManager or in parent)
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var player_hand = main_node.get_node_or_null("PlayerHand")
	
	if player_hand and player_hand.has_method("remove_card_from_hand"):
		player_hand.remove_card_from_hand(card)
		print("[CardManager] Notified PlayerHand that card was played: ", card.name)
