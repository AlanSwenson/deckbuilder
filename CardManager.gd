extends Node2D

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var dragged_card: Node2D = null  # Track which specific card is being dragged

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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

# Connect a card to the drag system
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
		
		# Connect to the input_event signal with a lambda that captures the card
		# Each card gets its own unique connection, so no need to check for duplicates
		card_area.input_event.connect(
			func(viewport: Node, event: InputEvent, shape_idx: int):
				_on_card_input_event(card, viewport, event, shape_idx)
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Update card position while dragging
	if is_dragging and dragged_card:
		var mouse_pos = get_global_mouse_position()
		dragged_card.global_position = mouse_pos - drag_offset
		# Debug log every 60 frames while dragging
		if Engine.get_process_frames() % 60 == 0:
			print("[CardManager] _process() - Dragging ", dragged_card.name,
				" | Mouse: ", mouse_pos, " | Card: ", dragged_card.global_position)
	
	# Check if mouse button was released (global check)
	if is_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if dragged_card:
			print("[CardManager] _process() - DRAGGING STOPPED (mouse released globally) for ",
				dragged_card.name)
			_check_and_snap_to_slot(dragged_card)
		is_dragging = false
		dragged_card = null


# Handle input events from the Area2D
# card parameter is passed from the lambda that captures it
func _on_card_input_event(
	card: Node2D, _viewport: Node, event: InputEvent, _shape_idx: int
) -> void:
	print("[CardManager] _on_card_input_event() - Event from ", card.name,
		" | Event type: ", event.get_class())
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				print("[CardManager] _on_card_input_event() - Left mouse button PRESSED on ",
					card.name)
				# Only start dragging if we're not already dragging another card
				if not is_dragging:
					is_dragging = true
					dragged_card = card
					var mouse_pos = get_global_mouse_position()
					drag_offset = mouse_pos - card.global_position
					print("[CardManager] _on_card_input_event() - DRAGGING STARTED for ",
						card.name, " | Mouse: ", mouse_pos, " | Card: ", card.global_position,
						" | Offset: ", drag_offset)
			else:
				print("[CardManager] _on_card_input_event() - Left mouse button RELEASED on ",
					card.name)
				# Only stop dragging if this is the card we're dragging
				if is_dragging and dragged_card == card:
					_check_and_snap_to_slot(card)
					is_dragging = false
					dragged_card = null
					print("[CardManager] _on_card_input_event() - DRAGGING STOPPED for ",
						card.name)

# Check if a card overlaps any CardSlot and snap it if it does
func _check_and_snap_to_slot(card: Node2D) -> void:
	if not card:
		return
	
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
	
	# If no overlapping slots, return
	if overlapping_slots.is_empty():
		return
	
	# If only one overlapping slot, snap to it
	if overlapping_slots.size() == 1:
		overlapping_slots[0].snap_card(card)
		print("[CardManager] Card snapped to slot: ", overlapping_slots[0].name)
		return
	
	# Multiple overlapping slots - find the one closest to mouse position
	var mouse_pos = get_global_mouse_position()
	var closest_slot = null
	var closest_distance = INF
	
	for slot in overlapping_slots:
		if slot.has_method("get_distance_to_point"):
			var distance = slot.get_distance_to_point(mouse_pos)
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

# Recursively find all CardSlot nodes in the scene tree
func _find_card_slots(node: Node, result: Array) -> void:
	# Check if this node is a CardSlot by name or by script
	var is_card_slot = node.name.begins_with("CardSlot")
	var has_snap_method = node.get_script() and node.has_method("snap_card")
	if is_card_slot or has_snap_method:
		result.append(node)
	
	for child in node.get_children():
		_find_card_slots(child, result)
