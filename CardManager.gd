extends Node2D

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var dragged_card: Node2D = null  # Track which specific card is being dragged

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find all card nodes (they all start with "Card")
	var card_nodes = []
	for child in get_children():
		if child.name.begins_with("Card"):
			card_nodes.append(child)
	
	print("[CardManager] _ready() - Found ", card_nodes.size(), " card(s)")
	
	# Connect to each card's Area2D using a lambda that captures the card reference
	for card in card_nodes:
		var card_area = card.get_node_or_null("Area2D")
		if card_area:
			# Ensure the Area2D can receive input
			card_area.input_pickable = true
			# Connect to the input_event signal with a lambda that captures the card
			card_area.input_event.connect(func(viewport: Node, event: InputEvent, shape_idx: int):
				_on_card_input_event(card, viewport, event, shape_idx)
			)
			print("[CardManager] _ready() - Connected to Area2D for card: ", card.name)
		else:
			print("[CardManager] ERROR - CardArea not found for card: ", card.name)


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
					is_dragging = false
					dragged_card = null
					print("[CardManager] _on_card_input_event() - DRAGGING STOPPED for ",
						card.name)
