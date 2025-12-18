extends VBoxContainer

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
	filter_all_btn = $FilterBar/FilterAll
	filter_sulfur_btn = $FilterBar/FilterSulfur
	filter_mercury_btn = $FilterBar/FilterMercury
	filter_salt_btn = $FilterBar/FilterSalt
	filter_vitae_btn = $FilterBar/FilterVitae
	filter_aether_btn = $FilterBar/FilterAether
	
	sort_name_btn = $SortBar/SortName
	sort_rarity_btn = $SortBar/SortRarity
	sort_element_btn = $SortBar/SortElement
	
	grid_container = $ScrollContainer/GridContainer
	summary_label = $SummaryLabel
	
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
		elif current_filter == FilterElement.MERCURY:
			if card.element == CardData.ElementType.MERCURY:
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

const CARD_SCENE = preload("res://scenes/Card.tscn")

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
	# Create a SubViewportContainer to properly render the Node2D Card scene
	var viewport_container = SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(148, 209)  # Card scene size
	viewport_container.name = "CardDisplay_" + str(index)
	viewport_container.stretch = true
	
	# Create SubViewport for the 2D card
	var viewport = SubViewport.new()
	viewport.size = Vector2i(148, 209)
	viewport.transparent_bg = true
	viewport_container.add_child(viewport)
	
	# Instantiate the Card scene
	var card_instance = CARD_SCENE.instantiate()
	card_instance.set_card_data(card_data)
	card_instance.position = Vector2(74, 104.5)  # Center of viewport
	# Make sure card labels are visible (they start with alpha 0)
	_make_card_labels_visible(card_instance)
	viewport.add_child(card_instance)
	
	return viewport_container

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
		"SpecialLabel"
	]
	
	for label_name in labels:
		var label = card_node.get_node_or_null(label_name)
		if label:
			label.modulate = Color(1, 1, 1, 1)
			label.visible = true

func _update_summary():
	if not SaveManager or not SaveManager.current_save_data:
		summary_label.text = "No collection loaded"
		return
	
	var summary = SaveManager.current_save_data.get_collection_summary()
	var filtered_count = _get_filtered_cards().size()
	
	var text = "Showing %d cards | Total: %d | Common: %d | Uncommon: %d"
	text += " | Rare: %d | Epic: %d | Legendary: %d"
	summary_label.text = text % [
		filtered_count,
		summary["total"],
		summary["common"],
		summary["uncommon"],
		summary["rare"],
		summary["epic"],
		summary["legendary"]
	]
