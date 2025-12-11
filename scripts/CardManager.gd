extends Node2D

# Reference to InputManager
var input_manager: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find InputManager
	input_manager = get_node_or_null("../InputManager")
	if not input_manager:
		input_manager = get_tree().current_scene.get_node_or_null("InputManager")
	
	# Connect to child_added signal to handle dynamically added cards
	child_entered_tree.connect(_on_child_added)
	
	# Find all card nodes (they all start with "Card")
	var card_nodes = []
	for child in get_children():
		if child.name.begins_with("Card"):
			card_nodes.append(child)
	
	print("[CardManager] _ready() - Found ", card_nodes.size(), " card(s)")
	
	# Connect to each card's Area2D
	for card in card_nodes:
		_connect_card(card)

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

# Check if a card overlaps any CardSlot and snap it if it does
# Returns true if the card was snapped to a slot, false otherwise
func check_and_snap_to_slot(card: Node2D) -> bool:
	if not card:
		return false
	
	# Find all CardSlot nodes in the scene
	# (they should be siblings of CardManager or in parent)
	var main_node = get_parent() if get_parent() else get_tree().current_scene
	var card_slots = []
	_find_card_slots(main_node, card_slots)
	
	# Find all slots that overlap with the card
	var overlapping_slots = []
	for slot in card_slots:
		if slot.has_method("is_card_overlapping"):
			if slot.is_card_overlapping(card):
				overlapping_slots.append(slot)
	
	# If no overlapping slots, return false
	if overlapping_slots.is_empty():
		return false
	
	# If only one overlapping slot, snap to it
	if overlapping_slots.size() == 1:
		overlapping_slots[0].snap_card(card)
		print("[CardManager] Card snapped to slot: ", overlapping_slots[0].name)
		return true
	
	# Multiple overlapping slots - find the one closest to mouse position
	var mouse_pos = get_global_mouse_position()
	var closest_slot = null
	var closest_distance = INF
	
	for slot in overlapping_slots:
		if slot.has_method("get_distance_to_point"):
			var distance = slot.get_distance_to_point(
				mouse_pos
			)
			if distance < closest_distance:
				closest_distance = distance
				closest_slot = slot
		else:
			# Fallback: use distance from global_position if method doesn't exist
			var distance = slot.global_position.distance_to(mouse_pos)
			if distance < closest_distance:
				closest_distance = distance
				closest_slot = slot
	
	# Snap to the closest slot
	if closest_slot and closest_slot.has_method("snap_card"):
		closest_slot.snap_card(card)
		print(
			"[CardManager] Card snapped to closest slot: ",
			closest_slot.name,
			" (distance: ",
			closest_distance,
			")"
		)
		return true
	
	return false

# Recursively find all CardSlot nodes in the scene tree
func _find_card_slots(node: Node, result: Array) -> void:
	# Check if this node is a CardSlot by name or by script
	var is_card_slot = node.name.begins_with("CardSlot")
	var has_snap_method = (
		node.get_script() and node.has_method("snap_card")
	)
	if is_card_slot or has_snap_method:
		result.append(node)
	
	for child in node.get_children():
		_find_card_slots(child, result)

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
