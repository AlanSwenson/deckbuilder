extends CanvasLayer

@onready var close_button = $CenterContainer/VBoxContainer/Button
@onready var grid_container = $CenterContainer/VBoxContainer/ScrollContainer/GridContainer

var player_deck: Node2D = null
var player_hand: Node2D = null

func _ready():
	# Connect the close button
	close_button.pressed.connect(_on_close_pressed)
	
	# Find PlayerDeck and PlayerHand nodes
	player_deck = get_tree().current_scene.get_node_or_null("PlayerDeck")
	if not player_deck:
		print("[DeckView] WARNING: PlayerDeck not found")
	
	player_hand = get_tree().current_scene.get_node_or_null("PlayerHand")
	if not player_hand:
		print("[DeckView] WARNING: PlayerHand not found")
	
	# Start hidden
	hide()

func open():
	show()
	display_deck_cards()

func close():
	hide()
	clear_displayed_cards()

func _on_close_pressed():
	close()

# Optional: Press ESC to close
func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close()

func display_deck_cards():
	# Clear existing cards
	clear_displayed_cards()
	
	if not player_deck:
		print("[DeckView] ERROR: Cannot display cards, PlayerDeck not found")
		return
	
	# Get the original full deck
	var all_cards: Array[CardData] = []
	if player_deck and "original_deck" in player_deck:
		if player_deck.original_deck.size() > 0:
			all_cards = player_deck.original_deck.duplicate(true)
		else:
			# Fallback: combine deck + discard + hand to show all cards
			all_cards.append_array(player_deck.deck)
			all_cards.append_array(player_deck.discard_pile)
			# Add cards from hand
			if player_hand and "player_hand" in player_hand:
				for card_node in player_hand.player_hand:
					if card_node and "card_data" in card_node and card_node.card_data:
						all_cards.append(card_node.card_data)
	
	# Get cards currently in hand - count by card name
	var hand_card_counts: Dictionary = {}
	if player_hand and "player_hand" in player_hand:
		for card_node in player_hand.player_hand:
			if card_node and "card_data" in card_node and card_node.card_data:
				var card_name = card_node.card_data.card_name
				if card_name in hand_card_counts:
					hand_card_counts[card_name] += 1
				else:
					hand_card_counts[card_name] = 1
	
	# Track how many of each card we've marked so far
	var marked_counts: Dictionary = {}
	
	var total_in_hand = 0
	for count in hand_card_counts.values():
		total_in_hand += count
	print("[DeckView] Displaying ", all_cards.size(), " cards (", total_in_hand, " in hand)")
	
	# Create card displays for each card data
	for i in range(all_cards.size()):
		var card_data = all_cards[i]
		if not card_data:
			continue
		
		# Create a simple Control-based card display for the grid
		var card_display = Control.new()
		card_display.custom_minimum_size = Vector2(89, 125)  # Scaled card size
		card_display.name = "CardDisplay_" + str(i)
		
		# Create a background panel with element color tint
		var panel = Panel.new()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.2, 0.2, 0.2, 1.0)  # Dark background
		style_box.border_color = card_data.get_element_color()
		style_box.border_width_left = 2
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", style_box)
		card_display.add_child(panel)
		
		# Add card name label
		var name_label = Label.new()
		name_label.text = card_data.card_name
		name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		name_label.offset_top = 5
		name_label.offset_bottom = 30
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_color_override("font_outline_color", Color.BLACK)
		name_label.add_theme_constant_override("outline_size", 2)
		card_display.add_child(name_label)
		
		# Add element info at bottom
		var element_label = Label.new()
		element_label.text = card_data.get_element_name()
		element_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		element_label.offset_top = -20
		element_label.add_theme_font_size_override("font_size", 10)
		element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		element_label.add_theme_color_override("font_color", card_data.get_element_color())
		card_display.add_child(element_label)
		
		# Check if this card is in hand and add hand icon
		var is_in_hand = false
		var card_name = card_data.card_name
		if card_name in hand_card_counts:
			# Check how many we've already marked
			var already_marked = marked_counts.get(card_name, 0)
			if already_marked < hand_card_counts[card_name]:
				is_in_hand = true
				marked_counts[card_name] = already_marked + 1
		
		if is_in_hand:
			# Add hand icon indicator
			var hand_icon = Label.new()
			hand_icon.text = "✋"  # Hand emoji
			hand_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			hand_icon.offset_left = 5
			hand_icon.offset_top = 5
			hand_icon.offset_right = 25
			hand_icon.offset_bottom = 25
			hand_icon.add_theme_font_size_override("font_size", 16)
			hand_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hand_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hand_icon.add_theme_color_override("font_color", Color.YELLOW)
			hand_icon.add_theme_color_override("font_outline_color", Color.BLACK)
			hand_icon.add_theme_constant_override("outline_size", 2)
			card_display.add_child(hand_icon)
		
		# Store card data reference
		card_display.set_meta("card_data", card_data)
		
		# Add to grid
		grid_container.add_child(card_display)
		
		print("[DeckView] Added card: ", card_data.card_name, " at index ", i, " (in hand: ", is_in_hand, ")")

func clear_displayed_cards():
	# Clear all children from grid container
	for child in grid_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
