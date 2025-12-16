extends Control

signal deck_saved()
signal editor_closed()

const MIN_DECK_SIZE = 20
const MAX_DECK_SIZE = 40
const CARD_SCENE = preload("res://scenes/Card.tscn")

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
	
	# Create a button wrapper for clickability
	var card_button = Button.new()
	card_button.custom_minimum_size = Vector2(148, 209)
	card_button.text = ""
	card_button.flat = true
	
	# Create SubViewportContainer to properly render the Node2D Card scene
	var viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_button.add_child(viewport_container)
	
	# Create SubViewport for the 2D card
	var viewport = SubViewport.new()
	viewport.size = Vector2i(148, 209)
	viewport.transparent_bg = true
	viewport_container.add_child(viewport)
	
	# Instantiate the Card scene
	var card_instance = CARD_SCENE.instantiate()
	card_instance.set_card_data(card_data)
	card_instance.position = Vector2(74, 104.5)  # Center of viewport
	# Make sure card labels are visible
	_make_card_labels_visible(card_instance)
	viewport.add_child(card_instance)
	
	# Add visual indicator if in deck (on top of button)
	if in_deck:
		var overlay = ColorRect.new()
		overlay.color = Color(0.2, 0.4, 0.2, 0.3)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_button.add_child(overlay)
		
		var indicator = Label.new()
		indicator.text = "IN DECK"
		indicator.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		indicator.offset_left = 5
		indicator.offset_top = 5
		indicator.offset_right = 80
		indicator.offset_bottom = 20
		indicator.add_theme_font_size_override("font_size", 10)
		indicator.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4, 1))
		indicator.add_theme_color_override("font_outline_color", Color.BLACK)
		indicator.add_theme_constant_override("outline_size", 2)
		indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_button.add_child(indicator)
	
	# Connect click to add to deck
	card_button.pressed.connect(_on_collection_card_clicked.bind(index))
	
	return card_button

func _make_card_labels_visible(card_node: Node):
	# Find all labels and make them visible
	var labels = [
		"CardNumberLabel",
		"CardNameLabel",
		"ElementSymbolLabel",
		"DescriptionLabel",
		"DamageLabel",
		"HealLabel",
		"BlockLabel",
		"DrawLabel",
		"SpecialLabel"
	]
	
	for label_name in labels:
		var label = card_node.get_node_or_null(label_name)
		if label:
			label.modulate = Color(1, 1, 1, 1)
			label.visible = true

func _create_deck_card_display(card_dict: Dictionary, indices: Array, count: int) -> Control:
	var card_data = CardData.from_save_dict(card_dict)
	
	# Create a button wrapper for clickability
	var card_button = Button.new()
	card_button.custom_minimum_size = Vector2(148, 209)
	card_button.text = ""
	card_button.flat = true
	
	# Create SubViewportContainer to properly render the Node2D Card scene
	var viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_button.add_child(viewport_container)
	
	# Create SubViewport for the 2D card
	var viewport = SubViewport.new()
	viewport.size = Vector2i(148, 209)
	viewport.transparent_bg = true
	viewport_container.add_child(viewport)
	
	# Instantiate the Card scene
	var card_instance = CARD_SCENE.instantiate()
	card_instance.set_card_data(card_data)
	card_instance.position = Vector2(74, 104.5)  # Center of viewport
	# Make sure card labels are visible
	_make_card_labels_visible(card_instance)
	viewport.add_child(card_instance)
	
	# Add count badge overlay (on top of button)
	var count_badge = Label.new()
	count_badge.text = "x%d" % count
	count_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	count_badge.offset_left = -40
	count_badge.offset_top = 5
	count_badge.offset_right = -5
	count_badge.offset_bottom = 25
	count_badge.add_theme_font_size_override("font_size", 18)
	count_badge.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	count_badge.add_theme_color_override("font_outline_color", Color.BLACK)
	count_badge.add_theme_constant_override("outline_size", 2)
	count_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_button.add_child(count_badge)
	
	# Click to remove one copy
	card_button.pressed.connect(_on_deck_card_clicked.bind(indices[0]))
	
	return card_button

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

