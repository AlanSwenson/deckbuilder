extends Node2D

# Right-side UI elements that need to be positioned relative to viewport right edge
@onready var deck_slot_enemy: Node2D = null
@onready var discard_slot_enemy: Node2D = null
@onready var view_deck_button: Control = null
@onready var play_hand_button: Control = null
@onready var turn_history: Control = null

# Offset from right edge (in pixels)
const RIGHT_EDGE_OFFSET = 86  # Distance from right edge
const DECK_SLOT_Y = 113
const DISCARD_SLOT_Y = 335
const BUTTON_WIDTH = 120
const BUTTON_SPACING = 20
const VIEW_DECK_BUTTON_Y = 940
const PLAY_HAND_BUTTON_Y = 880
const TURN_HISTORY_WIDTH = 263  # 1594 - 1331
const TURN_HISTORY_HEIGHT = 856  # 859 - 3

func _ready() -> void:
	# Wait a frame to ensure viewport is ready
	await get_tree().process_frame
	
	# Find all right-side UI elements
	deck_slot_enemy = get_node_or_null("DeckSlotEnemy")
	discard_slot_enemy = get_node_or_null("DiscardSlotEnemy")
	view_deck_button = get_node_or_null("ViewDeckButton")
	play_hand_button = get_node_or_null("PlayHandButton")
	turn_history = get_node_or_null("TurnHistory")
	
	# Position all elements
	_update_positions()
	
	# Connect to viewport size changed signal
	var viewport = get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	_update_positions()

func _update_positions() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		var window = get_window()
		if window:
			viewport_size = window.size
		if viewport_size.x <= 0 or viewport_size.y <= 0:
			viewport_size = Vector2(1600, 1000)  # Fallback
	
	var right_edge_x = viewport_size.x - RIGHT_EDGE_OFFSET
	
	# Position Node2D elements (DeckSlotEnemy, DiscardSlotEnemy)
	if deck_slot_enemy:
		deck_slot_enemy.position = Vector2(right_edge_x, DECK_SLOT_Y)
	
	if discard_slot_enemy:
		discard_slot_enemy.position = Vector2(right_edge_x, DISCARD_SLOT_Y)
	
	# Position Control elements (Buttons, TurnHistory) using anchors
	if view_deck_button:
		view_deck_button.offset_left = right_edge_x - BUTTON_WIDTH
		view_deck_button.offset_right = right_edge_x
		view_deck_button.offset_top = VIEW_DECK_BUTTON_Y
		view_deck_button.offset_bottom = VIEW_DECK_BUTTON_Y + 40
	
	if play_hand_button:
		play_hand_button.offset_left = right_edge_x - BUTTON_WIDTH - BUTTON_SPACING - 100
		play_hand_button.offset_right = right_edge_x - BUTTON_SPACING
		play_hand_button.offset_top = PLAY_HAND_BUTTON_Y
		play_hand_button.offset_bottom = PLAY_HAND_BUTTON_Y + 40
	
	if turn_history:
		turn_history.offset_left = right_edge_x - TURN_HISTORY_WIDTH
		turn_history.offset_right = right_edge_x
		turn_history.offset_top = 3.0
		turn_history.offset_bottom = 3.0 + TURN_HISTORY_HEIGHT
