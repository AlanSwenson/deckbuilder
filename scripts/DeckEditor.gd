extends Control

signal deck_saved()
signal editor_closed()

const MIN_DECK_SIZE = 20
const MAX_DECK_SIZE = 40

# Filter options
enum FilterElement { ALL, SULFUR, MERCURY, SALT, VITAE, AETHER }

var current_filter: FilterElement = FilterElement.ALL
var editing_deck_name: String = ""
var is_new_deck: bool = false

# Working copy of deck cards (indices into collection)
var deck_card_indices: Array[int] = []

# UI node references
var deck_name_input: LineEdit
var collection_grid: GridContainer
var deck_grid: GridContainer
var card_count_label: Label
var save_button: Button
var cancel_button: Button
var clear_button: Button
var filter_buttons: Dictionary = {}

func _ready():
	# Get base paths
	var vbox = $PanelContainer/VBoxContainer
	var content = vbox.get_node("ContentHBox")
	var coll_panel = content.get_node("CollectionPanel/VBoxContainer")
	var deck_panel = content.get_node("DeckPanel/VBoxContainer")
	
	# Get node references
	deck_name_input = vbox.get_node("Header/DeckNameInput")
	collection_grid = coll_panel.get_node("ScrollContainer/CollectionGrid")
	deck_grid = deck_panel.get_node("ScrollContainer/DeckGrid")
	card_count_label = deck_panel.get_node("CardCountLabel")
	save_button = vbox.get_node("Footer/SaveButton")
	cancel_button = vbox.get_node("Footer/CancelButton")
	clear_button = deck_panel.get_node("ClearButton")
	
	# Get filter buttons
	var filter_bar = coll_panel.get_node("FilterBar")
	filter_buttons[FilterElement.ALL] = filter_bar.get_node("FilterAll")
	filter_buttons[FilterElement.SULFUR] = filter_bar.get_node("FilterSulfur")
	filter_buttons[FilterElement.MERCURY] = filter_bar.get_node("FilterMercury")
	filter_buttons[FilterElement.SALT] = filter_bar.get_node("FilterSalt")
	filter_buttons[FilterElement.VITAE] = filter_bar.get_node("FilterVitae")
	filter_buttons[FilterElement.AETHER] = filter_bar.get_node("FilterAether")
	
	# Connect buttons
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	
	# Connect filter buttons
	for filter_type in filter_buttons:
		filter_buttons[filter_type].pressed.connect(_on_filter_pressed.bind(filter_type))

func open(deck_name: String = ""):
	editing_deck_name = deck_name
	is_new_deck = (deck_name == "")
	deck_card_indices.clear()
	
	if is_new_deck:
		deck_name_input.text = "New Deck"
		deck_name_input.editable = true
	else:
		deck_name_input.text = deck_name
		deck_name_input.editable = true
		_load_existing_deck(deck_name)
	
	current_filter = FilterElement.ALL
	_update_filter_buttons()
	_refresh_collection_display()
	_refresh_deck_display()
	_update_card_count()
	
	visible = true
	print("[DeckEditor] Opened for deck: '%s' (new: %s)" % [deck_name, is_new_deck])

func _load_existing_deck(deck_name: String):
	if not SaveManager or not SaveManager.current_save_data:
		return
	
	var save_data = SaveManager.current_save_data
	if deck_name not in save_data.decks:
		return
	
	var deck_cards = save_data.decks[deck_name]
	var collection = save_data.card_collection
	
	# Find collection indices for each card in the deck
	# Note: This assumes each card in the deck matches exactly one in the collection
	var used_indices: Array[int] = []
	
	for deck_card in deck_cards:
		for i in range(collection.size()):
			if i in used_indices:
				continue
			if _cards_match(collection[i], deck_card):
				deck_card_indices.append(i)
				used_indices.append(i)
				break

func _cards_match(card1: Dictionary, card2: Dictionary) -> bool:
	if card1.get("card_name") != card2.get("card_name"):
		return false
	if card1.get("element") != card2.get("element"):
		return false
	if card1.get("rarity") != card2.get("rarity"):
		return false
	
	var slots1 = card1.get("slots", [])
	var slots2 = card2.get("slots", [])
	if slots1.size() != slots2.size():
		return false
	
	for i in range(slots1.size()):
		if slots1[i].get("ability_id") != slots2[i].get("ability_id"):
			return false
		if slots1[i].get("rolled_value") != slots2[i].get("rolled_value"):
			return false
	
	return true

func _on_filter_pressed(filter: FilterElement):
	current_filter = filter
	_update_filter_buttons()
	_refresh_collection_display()

func _update_filter_buttons():
	for filter_type in filter_buttons:
		filter_buttons[filter_type].button_pressed = (filter_type == current_filter)

func _get_filtered_collection() -> Array:
	if not SaveManager or not SaveManager.current_save_data:
		return []
	
	var collection = SaveManager.current_save_data.card_collection
	var filtered: Array = []
	
	for i in range(collection.size()):
		var card_dict = collection[i]
		var matches_filter = false
		
		if current_filter == FilterElement.ALL:
			matches_filter = true
		else:
			var element = card_dict.get("element", 0)
			match current_filter:
				FilterElement.SULFUR:
					matches_filter = (element == CardData.ElementType.SULFUR)
				FilterElement.MERCURY:
					matches_filter = (element == CardData.ElementType.MERCURY)
				FilterElement.SALT:
					matches_filter = (element == CardData.ElementType.SALT)
				FilterElement.VITAE:
					matches_filter = (element == CardData.ElementType.VITAE)
				FilterElement.AETHER:
					matches_filter = (element == CardData.ElementType.AETHER)
		
		if matches_filter:
			filtered.append({"index": i, "card": card_dict})
	
	# Sort by name
	filtered.sort_custom(func(a, b): 
		return a["card"].get("card_name", "") < b["card"].get("card_name", "")
	)
	
	return filtered

func _refresh_collection_display():
	# Clear existing
	for child in collection_grid.get_children():
		child.queue_free()
	
	var filtered = _get_filtered_collection()
	
	for item in filtered:
		var card_dict = item["card"]
		var index = item["index"]
		var in_deck = index in deck_card_indices
		var card_display = _create_collection_card_display(card_dict, index, in_deck)
		collection_grid.add_child(card_display)

func _refresh_deck_display():
	# Clear existing
	for child in deck_grid.get_children():
		child.queue_free()
	
	if not SaveManager or not SaveManager.current_save_data:
		return
	
	var collection = SaveManager.current_save_data.card_collection
	
	# Group cards by name for display
	var grouped: Dictionary = {}
	for idx in deck_card_indices:
		if idx < collection.size():
			var card_dict = collection[idx]
			var card_name = card_dict.get("card_name", "Unknown")
			if card_name not in grouped:
				grouped[card_name] = {"card": card_dict, "indices": [], "count": 0}
			grouped[card_name]["indices"].append(idx)
			grouped[card_name]["count"] += 1
	
	# Sort by name
	var names = grouped.keys()
	names.sort()
	
	for card_name in names:
		var data = grouped[card_name]
		var card_display = _create_deck_card_display(data["card"], data["indices"], data["count"])
		deck_grid.add_child(card_display)

func _create_collection_card_display(card_dict: Dictionary, index: int, in_deck: bool) -> Control:
	var card_data = CardData.from_save_dict(card_dict)
	
	var card_display = Button.new()
	card_display.custom_minimum_size = Vector2(100, 140)
	card_display.text = ""
	card_display.clip_text = true
	
	# Style based on whether it's in the deck
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 1.0) if not in_deck else Color(0.1, 0.15, 0.1, 1.0)
	style.border_color = card_data.get_element_color() if not in_deck else Color(0.3, 0.5, 0.3, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	card_display.add_theme_stylebox_override("normal", style)
	card_display.add_theme_stylebox_override("hover", style)
	card_display.add_theme_stylebox_override("pressed", style)
	
	# Content container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	card_display.add_child(vbox)
	
	# Card name
	var name_label = Label.new()
	name_label.text = card_data.card_name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)
	
	# Element symbol
	var element_label = Label.new()
	element_label.text = _get_element_symbol(card_data.element)
	element_label.add_theme_font_size_override("font_size", 24)
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(element_label)
	
	# Stats
	var stats_label = Label.new()
	var stats = []
	if card_data.get_total_damage() > 0:
		stats.append(str(card_data.get_total_damage()) + " DMG")
	if card_data.get_total_block() > 0:
		stats.append(str(card_data.get_total_block()) + " BLK")
	if card_data.get_total_heal() > 0:
		stats.append("+" + str(card_data.get_total_heal()) + " HP")
	stats_label.text = " ".join(stats) if stats.size() > 0 else ""
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	
	# In deck indicator
	if in_deck:
		var indicator = Label.new()
		indicator.text = "IN DECK"
		indicator.add_theme_font_size_override("font_size", 8)
		indicator.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4, 1))
		indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(indicator)
	
	# Connect click to add to deck
	card_display.pressed.connect(_on_collection_card_clicked.bind(index))
	
	return card_display

func _create_deck_card_display(card_dict: Dictionary, indices: Array, count: int) -> Control:
	var card_data = CardData.from_save_dict(card_dict)
	
	var card_display = Button.new()
	card_display.custom_minimum_size = Vector2(100, 120)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	style.border_color = card_data.get_element_color()
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	card_display.add_theme_stylebox_override("normal", style)
	card_display.add_theme_stylebox_override("hover", style)
	card_display.add_theme_stylebox_override("pressed", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	card_display.add_child(vbox)
	
	# Card name with count
	var name_label = Label.new()
	name_label.text = card_data.card_name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)
	
	# Count badge
	var count_label = Label.new()
	count_label.text = "x%d" % count
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(count_label)
	
	# Element
	var element_label = Label.new()
	element_label.text = _get_element_symbol(card_data.element)
	element_label.add_theme_font_size_override("font_size", 18)
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(element_label)
	
	# Click to remove one copy
	card_display.pressed.connect(_on_deck_card_clicked.bind(indices[0]))
	
	return card_display

func _on_collection_card_clicked(index: int):
	if deck_card_indices.size() >= MAX_DECK_SIZE:
		print("[DeckEditor] Deck is at max size (%d)" % MAX_DECK_SIZE)
		return
	
	# Add card to deck
	deck_card_indices.append(index)
	_refresh_collection_display()
	_refresh_deck_display()
	_update_card_count()

func _on_deck_card_clicked(index: int):
	# Remove one copy of this card from deck
	var pos = deck_card_indices.find(index)
	if pos >= 0:
		deck_card_indices.remove_at(pos)
	_refresh_collection_display()
	_refresh_deck_display()
	_update_card_count()

func _update_card_count():
	var count = deck_card_indices.size()
	var status = ""
	
	if count < MIN_DECK_SIZE:
		status = " (need %d more)" % (MIN_DECK_SIZE - count)
		card_count_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	elif count > MAX_DECK_SIZE:
		status = " (over limit!)"
		card_count_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	else:
		card_count_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
	
	card_count_label.text = "%d / %d cards%s" % [count, MAX_DECK_SIZE, status]
	
	# Enable/disable save button based on validity
	save_button.disabled = (count < MIN_DECK_SIZE or count > MAX_DECK_SIZE)

func _on_clear_pressed():
	deck_card_indices.clear()
	_refresh_collection_display()
	_refresh_deck_display()
	_update_card_count()

func _on_save_pressed():
	var new_name = deck_name_input.text.strip_edges()
	
	if new_name == "":
		push_error("[DeckEditor] Deck name cannot be empty")
		return
	
	var deck_size = deck_card_indices.size()
	if deck_size < MIN_DECK_SIZE or deck_size > MAX_DECK_SIZE:
		var msg = "[DeckEditor] Deck size must be between %d and %d"
		push_error(msg % [MIN_DECK_SIZE, MAX_DECK_SIZE])
		return
	
	if not SaveManager or not SaveManager.current_save_data:
		push_error("[DeckEditor] No save data available")
		return
	
	var save_data = SaveManager.current_save_data
	var collection = save_data.card_collection
	
	# Build deck from indices
	var deck_cards: Array[Dictionary] = []
	for idx in deck_card_indices:
		if idx < collection.size():
			deck_cards.append(collection[idx].duplicate(true))
	
	# If renaming, delete old deck first
	if not is_new_deck and new_name != editing_deck_name:
		if editing_deck_name in save_data.decks:
			save_data.decks.erase(editing_deck_name)
			# Update current_deck_name if it was the renamed deck
			if save_data.current_deck_name == editing_deck_name:
				save_data.current_deck_name = new_name
	
	# Save the deck
	save_data.decks[new_name] = deck_cards
	
	# If this is a new deck or was the active deck, update current deck
	var was_active = save_data.current_deck_name == editing_deck_name
	var is_active = save_data.current_deck_name == new_name
	if is_new_deck or was_active or is_active:
		save_data.current_deck_name = new_name
		save_data.current_deck = deck_cards.duplicate(true)
	
	SaveManager.save_game()
	
	print("[DeckEditor] Saved deck '%s' with %d cards" % [new_name, deck_cards.size()])
	
	emit_signal("deck_saved")
	_close()

func _on_cancel_pressed():
	_close()

func _close():
	visible = false
	emit_signal("editor_closed")

func _get_element_symbol(element_type: CardData.ElementType) -> String:
	match element_type:
		CardData.ElementType.SULFUR:
			return "🔥"
		CardData.ElementType.MERCURY:
			return "💧"
		CardData.ElementType.SALT:
			return "⛰️"
		CardData.ElementType.VITAE:
			return "🌿"
		CardData.ElementType.AETHER:
			return "⭐"
	return "?"
