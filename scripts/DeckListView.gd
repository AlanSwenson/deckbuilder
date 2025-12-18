extends VBoxContainer

signal edit_deck_requested(deck_name: String)
signal deck_selected(deck_name: String)

# UI node references
var create_deck_button: Button
var deck_list_container: VBoxContainer

func _ready():
	create_deck_button = $CreateDeckButton
	deck_list_container = $ScrollContainer/DeckListContainer
	
	create_deck_button.pressed.connect(_on_create_deck_pressed)
	
	refresh()

func refresh():
	_display_decks()

func _display_decks():
	# Clear existing deck entries
	for child in deck_list_container.get_children():
		child.queue_free()
	
	if not SaveManager or not SaveManager.current_save_data:
		_add_no_decks_message()
		return
	
	var save_data = SaveManager.current_save_data
	var decks = save_data.decks
	
	if decks.is_empty():
		_add_no_decks_message()
		return
	
	# Sort deck names alphabetically
	var deck_names = decks.keys()
	deck_names.sort()
	
	for deck_name in deck_names:
		var deck_cards = decks[deck_name]
		var is_active = (deck_name == save_data.current_deck_name)
		var deck_entry = _create_deck_entry(deck_name, deck_cards.size(), is_active)
		deck_list_container.add_child(deck_entry)

func _add_no_decks_message():
	var label = Label.new()
	label.text = "No decks created yet. Click 'Create New Deck' to get started!"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_list_container.add_child(label)

func _create_deck_entry(deck_name: String, card_count: int, is_active: bool) -> Control:
	var entry = PanelContainer.new()
	entry.custom_minimum_size = Vector2(0, 60)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.25, 1.0) if not is_active else Color(0.25, 0.3, 0.35, 1.0)
	style_box.border_color = Color(0.4, 0.4, 0.5, 1.0) if not is_active else Color(0.4, 0.6, 0.8, 1.0)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	style_box.content_margin_left = 15
	style_box.content_margin_right = 15
	style_box.content_margin_top = 10
	style_box.content_margin_bottom = 10
	entry.add_theme_stylebox_override("panel", style_box)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(hbox)
	
	# Deck info section
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Deck name with active indicator
	var name_hbox = HBoxContainer.new()
	info_vbox.add_child(name_hbox)
	
	var name_label = Label.new()
	name_label.text = deck_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_hbox.add_child(name_label)
	
	if is_active:
		var active_label = Label.new()
		active_label.text = " [ACTIVE]"
		active_label.add_theme_font_size_override("font_size", 14)
		active_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4, 1))
		name_hbox.add_child(active_label)
	
	# Card count and validity
	var count_label = Label.new()
	var validity_text = ""
	if card_count < 20:
		validity_text = " (needs %d more cards)" % (20 - card_count)
	elif card_count > 40:
		validity_text = " (over limit by %d)" % (card_count - 40)
	count_label.text = "%d cards%s" % [card_count, validity_text]
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	info_vbox.add_child(count_label)
	
	# Buttons section
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 10)
	hbox.add_child(buttons_hbox)
	
	# Select button (only show if not active)
	if not is_active:
		var select_btn = Button.new()
		select_btn.text = "Select"
		select_btn.custom_minimum_size = Vector2(80, 35)
		select_btn.pressed.connect(_on_select_deck.bind(deck_name))
		buttons_hbox.add_child(select_btn)
	
	# Edit button
	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.custom_minimum_size = Vector2(70, 35)
	edit_btn.pressed.connect(_on_edit_deck.bind(deck_name))
	buttons_hbox.add_child(edit_btn)
	
	# Duplicate button
	var duplicate_btn = Button.new()
	duplicate_btn.text = "Copy"
	duplicate_btn.custom_minimum_size = Vector2(70, 35)
	duplicate_btn.pressed.connect(_on_duplicate_deck.bind(deck_name))
	buttons_hbox.add_child(duplicate_btn)
	
	# Delete button
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(80, 35)
	delete_btn.pressed.connect(_on_delete_deck.bind(deck_name))
	delete_btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	buttons_hbox.add_child(delete_btn)
	
	return entry

func _on_create_deck_pressed():
	emit_signal("edit_deck_requested", "")

func _on_select_deck(deck_name: String):
	if not SaveManager or not SaveManager.current_save_data:
		return
	
	SaveManager.current_save_data.set_active_deck(deck_name)
	SaveManager.save_game()
	emit_signal("deck_selected", deck_name)
	refresh()

func _on_edit_deck(deck_name: String):
	emit_signal("edit_deck_requested", deck_name)

func _on_duplicate_deck(deck_name: String):
	if not SaveManager or not SaveManager.current_save_data:
		return
	
	var save_data = SaveManager.current_save_data
	if deck_name not in save_data.decks:
		return
	
	# Find a unique name for the copy
	var copy_name = deck_name + " (Copy)"
	var counter = 1
	while copy_name in save_data.decks:
		counter += 1
		copy_name = deck_name + " (Copy %d)" % counter
	
	# Duplicate the deck
	var original_cards = save_data.decks[deck_name]
	save_data.decks[copy_name] = original_cards.duplicate(true)
	
	SaveManager.save_game()
	refresh()
	print("[DeckListView] Duplicated deck '%s' as '%s'" % [deck_name, copy_name])

func _on_delete_deck(deck_name: String):
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Delete deck '%s'?\n\nThis cannot be undone." % deck_name
	dialog.title = "Confirm Delete"
	dialog.confirmed.connect(_do_delete_deck.bind(deck_name))
	add_child(dialog)
	dialog.popup_centered()

func _do_delete_deck(deck_name: String):
	if not SaveManager or not SaveManager.current_save_data:
		return
	
	SaveManager.current_save_data.delete_deck(deck_name)
	SaveManager.save_game()
	refresh()
	print("[DeckListView] Deleted deck '%s'" % deck_name)
