extends Control

# Filter/sort options
enum SortBy { NAME, RARITY, ELEMENT }
enum FilterElement { ALL, SULFUR, MERCURY, SALT, VITAE, AETHER }

var current_sort: SortBy = SortBy.NAME
var current_filter: FilterElement = FilterElement.ALL

# UI node references
var filter_all_btn: Button
var filter_sulfur_btn: Button
var filter_mercury_btn: Button
var filter_salt_btn: Button
var filter_vitae_btn: Button
var filter_aether_btn: Button
var sort_name_btn: Button
var sort_rarity_btn: Button
var sort_element_btn: Button
var grid_container: GridContainer
var summary_label: Label

func _ready():
	# Get node references
	filter_all_btn = $VBoxContainer/FilterBar/FilterAll
	filter_sulfur_btn = $VBoxContainer/FilterBar/FilterSulfur
	filter_mercury_btn = $VBoxContainer/FilterBar/FilterMercury
	filter_salt_btn = $VBoxContainer/FilterBar/FilterSalt
	filter_vitae_btn = $VBoxContainer/FilterBar/FilterVitae
	filter_aether_btn = $VBoxContainer/FilterBar/FilterAether
	
	sort_name_btn = $VBoxContainer/SortBar/SortName
	sort_rarity_btn = $VBoxContainer/SortBar/SortRarity
	sort_element_btn = $VBoxContainer/SortBar/SortElement
	
	grid_container = $VBoxContainer/ScrollContainer/GridContainer
	summary_label = $VBoxContainer/SummaryLabel
	
	# Connect filter buttons
	filter_all_btn.pressed.connect(_on_filter_pressed.bind(FilterElement.ALL))
	filter_sulfur_btn.pressed.connect(_on_filter_pressed.bind(FilterElement.SULFUR))
	filter_mercury_btn.pressed.connect(_on_filter_pressed.bind(FilterElement.MERCURY))
	filter_salt_btn.pressed.connect(_on_filter_pressed.bind(FilterElement.SALT))
	filter_vitae_btn.pressed.connect(_on_filter_pressed.bind(FilterElement.VITAE))
	filter_aether_btn.pressed.connect(_on_filter_pressed.bind(FilterElement.AETHER))
	
	# Connect sort buttons
	sort_name_btn.pressed.connect(_on_sort_pressed.bind(SortBy.NAME))
	sort_rarity_btn.pressed.connect(_on_sort_pressed.bind(SortBy.RARITY))
	sort_element_btn.pressed.connect(_on_sort_pressed.bind(SortBy.ELEMENT))
	
	# Initial display
	refresh()

func refresh():
	_update_filter_button_states()
	_update_sort_button_states()
	_display_cards()
	_update_summary()

func _on_filter_pressed(filter: FilterElement):
	current_filter = filter
	refresh()

func _on_sort_pressed(sort: SortBy):
	current_sort = sort
	refresh()

func _update_filter_button_states():
	filter_all_btn.button_pressed = (current_filter == FilterElement.ALL)
	filter_sulfur_btn.button_pressed = (current_filter == FilterElement.SULFUR)
	filter_mercury_btn.button_pressed = (current_filter == FilterElement.MERCURY)
	filter_salt_btn.button_pressed = (current_filter == FilterElement.SALT)
	filter_vitae_btn.button_pressed = (current_filter == FilterElement.VITAE)
	filter_aether_btn.button_pressed = (current_filter == FilterElement.AETHER)

func _update_sort_button_states():
	sort_name_btn.button_pressed = (current_sort == SortBy.NAME)
	sort_rarity_btn.button_pressed = (current_sort == SortBy.RARITY)
	sort_element_btn.button_pressed = (current_sort == SortBy.ELEMENT)

func _get_filtered_cards() -> Array[CardData]:
	if not SaveManager or not SaveManager.current_save_data:
		return []
	
	var all_cards = SaveManager.current_save_data.get_collection_cards()
	var filtered: Array[CardData] = []
	
	for card in all_cards:
		if current_filter == FilterElement.ALL:
			filtered.append(card)
		elif current_filter == FilterElement.SULFUR and card.element == CardData.ElementType.SULFUR:
			filtered.append(card)
		elif current_filter == FilterElement.MERCURY and card.element == CardData.ElementType.MERCURY:
			filtered.append(card)
		elif current_filter == FilterElement.SALT and card.element == CardData.ElementType.SALT:
			filtered.append(card)
		elif current_filter == FilterElement.VITAE and card.element == CardData.ElementType.VITAE:
			filtered.append(card)
		elif current_filter == FilterElement.AETHER and card.element == CardData.ElementType.AETHER:
			filtered.append(card)
	
	return filtered

func _sort_cards(cards: Array[CardData]) -> Array[CardData]:
	var sorted = cards.duplicate()
	
	match current_sort:
		SortBy.NAME:
			sorted.sort_custom(func(a, b): return a.card_name < b.card_name)
		SortBy.RARITY:
			sorted.sort_custom(func(a, b): 
				if a.rarity != b.rarity:
					return a.rarity > b.rarity  # Higher rarity first
				return a.card_name < b.card_name
			)
		SortBy.ELEMENT:
			sorted.sort_custom(func(a, b):
				if a.element != b.element:
					return a.element < b.element
				return a.card_name < b.card_name
			)
	
	return sorted

func _display_cards():
	# Clear existing cards
	for child in grid_container.get_children():
		child.queue_free()
	
	var cards = _get_filtered_cards()
	cards = _sort_cards(cards)
	
	for i in range(cards.size()):
		var card_data = cards[i]
		var card_display = _create_card_display(card_data, i)
		grid_container.add_child(card_display)

func _create_card_display(card_data: CardData, index: int) -> Control:
	var card_display = Control.new()
	card_display.custom_minimum_size = Vector2(120, 170)
	card_display.name = "CardDisplay_" + str(index)
	
	# Create a background panel with element color border
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.18, 1.0)
	style_box.border_color = card_data.get_element_color()
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style_box)
	card_display.add_child(panel)
	
	# Rarity indicator bar at top
	var rarity_bar = ColorRect.new()
	rarity_bar.color = card_data.get_rarity_color()
	rarity_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	rarity_bar.offset_top = 3
	rarity_bar.offset_bottom = 8
	rarity_bar.offset_left = 3
	rarity_bar.offset_right = -3
	card_display.add_child(rarity_bar)
	
	# Card name label
	var name_label = Label.new()
	name_label.text = card_data.card_name
	name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_label.offset_top = 12
	name_label.offset_bottom = 40
	name_label.offset_left = 5
	name_label.offset_right = -5
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card_display.add_child(name_label)
	
	# Element symbol
	var element_label = Label.new()
	element_label.text = _get_element_symbol(card_data.element)
	element_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	element_label.offset_top = -30
	element_label.offset_bottom = 10
	element_label.add_theme_font_size_override("font_size", 32)
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_display.add_child(element_label)
	
	# Stats container at bottom
	var stats_container = HBoxContainer.new()
	stats_container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	stats_container.offset_top = -55
	stats_container.offset_bottom = -30
	stats_container.offset_left = 5
	stats_container.offset_right = -5
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_display.add_child(stats_container)
	
	# Add stat labels
	var damage = card_data.get_total_damage()
	var heal = card_data.get_total_heal()
	var block = card_data.get_total_block()
	
	if damage > 0:
		var dmg_label = Label.new()
		dmg_label.text = str(damage)
		dmg_label.add_theme_font_size_override("font_size", 14)
		dmg_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		stats_container.add_child(dmg_label)
	
	if block > 0:
		var block_label = Label.new()
		block_label.text = str(block)
		block_label.add_theme_font_size_override("font_size", 14)
		block_label.add_theme_color_override("font_color", Color(0.3, 0.5, 1, 1))
		stats_container.add_child(block_label)
	
	if heal > 0:
		var heal_label = Label.new()
		heal_label.text = "+" + str(heal)
		heal_label.add_theme_font_size_override("font_size", 14)
		heal_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3, 1))
		stats_container.add_child(heal_label)
	
	# Element and rarity text at bottom
	var info_label = Label.new()
	info_label.text = "%s • %s" % [card_data.get_element_name(), card_data.get_rarity_name()]
	info_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	info_label.offset_top = -25
	info_label.offset_bottom = -5
	info_label.offset_left = 5
	info_label.offset_right = -5
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	card_display.add_child(info_label)
	
	return card_display

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

func _update_summary():
	if not SaveManager or not SaveManager.current_save_data:
		summary_label.text = "No collection loaded"
		return
	
	var summary = SaveManager.current_save_data.get_collection_summary()
	var filtered_count = _get_filtered_cards().size()
	
	summary_label.text = "Showing %d cards | Total: %d | Common: %d | Uncommon: %d | Rare: %d | Epic: %d | Legendary: %d" % [
		filtered_count,
		summary["total"],
		summary["common"],
		summary["uncommon"],
		summary["rare"],
		summary["epic"],
		summary["legendary"]
	]
