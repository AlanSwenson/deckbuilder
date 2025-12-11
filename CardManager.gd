extends Node2D

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var card: Node2D = null
var card_area: Area2D = null

func _input(event):
	print("event: ", event)
	if event is InputEventMouseButton:
		print("mouse event")
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				print("[CardManager] _input() - Left mouse button PRESSED")
			else:
				print("[CardManager] _input() - Left mouse button RELEASED")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find the card node and its Area2D
	card = get_node_or_null("Card")
	print("[CardManager] _ready() - Card found: ", card != null)
	if card:
		card_area = card.get_node_or_null("Area2D")
		print("[CardManager] _ready() - CardArea found: ", card_area != null)
		if card_area:
			# Ensure the Area2D can receive input
			card_area.input_pickable = true
			# Connect to the input_event signal - this is the key!
			card_area.input_event.connect(_on_card_input_event)
			print("[CardManager] _ready() - CardArea input_pickable set to: ", card_area.input_pickable)
			print("[CardManager] _ready() - Connected to input_event signal")
		else:
			print("[CardManager] ERROR - CardArea not found!")
	else:
		print("[CardManager] ERROR - Card not found!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update card position while dragging
	if is_dragging and card:
		var mouse_pos = get_global_mouse_position()
		card.global_position = mouse_pos - drag_offset
		# Debug log every 60 frames while dragging
		if Engine.get_process_frames() % 60 == 0:
			print("[CardManager] _process() - Dragging | Mouse: ", mouse_pos, " | Card: ", card.global_position)
	
	# Check if mouse button was released (global check)
	if is_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_dragging = false
		print("[CardManager] _process() - DRAGGING STOPPED (mouse released globally)")


# Handle input events from the Area2D
func _on_card_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("[CardManager] _on_card_input_event() - Event received: ", event.get_class())
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				print("[CardManager] _on_card_input_event() - Left mouse button PRESSED on card")
				if card:
					is_dragging = true
					var mouse_pos = get_global_mouse_position()
					drag_offset = mouse_pos - card.global_position
					print("[CardManager] _on_card_input_event() - DRAGGING STARTED | Mouse: ", mouse_pos, " | Card: ", card.global_position, " | Offset: ", drag_offset)
			else:
				print("[CardManager] _on_card_input_event() - Left mouse button RELEASED on card")
				if is_dragging:
					is_dragging = false
					print("[CardManager] _on_card_input_event() - DRAGGING STOPPED")
