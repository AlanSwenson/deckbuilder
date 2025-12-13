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
	# Reset any hover effects on cards in the main scene
	_reset_main_scene_hovers()

func close():
	hide()
	clear_displayed_cards()

func _on_close_pressed():
	close()

# Reset hover effects on cards in the main scene when opening deck view
func _reset_main_scene_hovers():
	var input_manager = get_tree().current_scene.get_node_or_null("InputManager")
	if input_manager and input_manager.has_method("_reset_hover_effect"):
		input_manager._reset_hover_effect()

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
	
	# Get cards currently in player slots (in play) - count by card name
	var in_play_card_counts: Dictionary = {}
	var main_node = get_tree().current_scene
	var player_slots = []
	_find_player_slots(main_node, player_slots)
	
	for slot in player_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card) and "card_data" in current_card and current_card.card_data:
			var card_name = current_card.card_data.card_name
			if card_name in in_play_card_counts:
				in_play_card_counts[card_name] += 1
			else:
				in_play_card_counts[card_name] = 1
	
	# Get cards currently in discard pile - count by card name
	var discard_card_counts: Dictionary = {}
	if player_deck and "discard_pile" in player_deck:
		for card_data in player_deck.discard_pile:
			if card_data:
				var card_name = card_data.card_name
				if card_name in discard_card_counts:
					discard_card_counts[card_name] += 1
				else:
					discard_card_counts[card_name] = 1
	
	# Track how many of each card we've marked so far (for hand, in play, and discard)
	var marked_hand_counts: Dictionary = {}
	var marked_in_play_counts: Dictionary = {}
	var marked_discard_counts: Dictionary = {}
	
	var total_in_hand = 0
	for count in hand_card_counts.values():
		total_in_hand += count
	var total_in_play = 0
	for count in in_play_card_counts.values():
		total_in_play += count
	var total_in_discard = 0
	for count in discard_card_counts.values():
		total_in_discard += count
	print("[DeckView] Displaying ", all_cards.size(), " cards (", total_in_hand, " in hand, ", total_in_play, " in play, ", total_in_discard, " in discard)")
	
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
		
		# Check card status - priority: Hand > In Play > Discard > Nothing (in deck)
		var card_name = card_data.card_name
		var is_in_hand = false
		var is_in_play = false
		var is_in_discard = false
		
		# First check if card is in hand (highest priority)
		if card_name in hand_card_counts:
			var already_marked = marked_hand_counts.get(card_name, 0)
			if already_marked < hand_card_counts[card_name]:
				is_in_hand = true
				marked_hand_counts[card_name] = already_marked + 1
		
		# Check if card is in play (in player slot) - only if NOT in hand
		if not is_in_hand and card_name in in_play_card_counts:
			var already_marked = marked_in_play_counts.get(card_name, 0)
			if already_marked < in_play_card_counts[card_name]:
				is_in_play = true
				marked_in_play_counts[card_name] = already_marked + 1
		
		# Check if card is in discard - only if NOT in hand and NOT in play
		if not is_in_hand and not is_in_play and card_name in discard_card_counts:
			var already_marked = marked_discard_counts.get(card_name, 0)
			if already_marked < discard_card_counts[card_name]:
				is_in_discard = true
				marked_discard_counts[card_name] = already_marked + 1
		
		# Show only ONE indicator based on priority
		if is_in_hand:
			# Add hand icon indicator (top-left)
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
		elif is_in_play:
			# Add checkmark icon indicator (top-left) - card is in play (in a slot)
			var checkmark_icon = Label.new()
			checkmark_icon.text = "✓"  # Checkmark symbol
			checkmark_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			checkmark_icon.offset_left = 5
			checkmark_icon.offset_top = 5
			checkmark_icon.offset_right = 25
			checkmark_icon.offset_bottom = 25
			checkmark_icon.add_theme_font_size_override("font_size", 18)
			checkmark_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			checkmark_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			checkmark_icon.add_theme_color_override("font_color", Color.GREEN)
			checkmark_icon.add_theme_color_override("font_outline_color", Color.BLACK)
			checkmark_icon.add_theme_constant_override("outline_size", 2)
			card_display.add_child(checkmark_icon)
		elif is_in_discard:
			# Add X icon indicator (top-right) - only if NOT in hand and NOT in play
			var discard_icon = Label.new()
			discard_icon.text = "✕"  # X symbol
			discard_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			discard_icon.offset_left = -25
			discard_icon.offset_top = 5
			discard_icon.offset_right = -5
			discard_icon.offset_bottom = 25
			discard_icon.add_theme_font_size_override("font_size", 18)
			discard_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			discard_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			discard_icon.add_theme_color_override("font_color", Color.RED)
			discard_icon.add_theme_color_override("font_outline_color", Color.WHITE)
			discard_icon.add_theme_constant_override("outline_size", 2)
			card_display.add_child(discard_icon)
		# If none of the above, card is still in deck - show nothing
		
		# Store card data reference
		card_display.set_meta("card_data", card_data)
		
		# Add to grid
		grid_container.add_child(card_display)
		
		var status = "in deck"
		if is_in_hand:
			status = "in hand"
		elif is_in_play:
			status = "in play"
		elif is_in_discard:
			status = "in discard"
		print("[DeckView] Added card: ", card_data.card_name, " at index ", i, " (", status, ")")

func clear_displayed_cards():
	# Clear all children from grid container
	for child in grid_container.get_children():
		if is_instance_valid(child):
			child.queue_free()

# Recursively find all player slots
func _find_player_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("PlayerSlot"):
		result.append(node)
	
	for child in node.get_children():
		_find_player_slots(child, result)
