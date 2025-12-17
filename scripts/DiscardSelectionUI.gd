extends CanvasLayer
class_name DiscardSelectionUI

const CARD_SCENE = preload("res://scenes/Card.tscn")

# UI references
var panel: Panel = null
var title_label: Label = null
var instruction_label: Label = null
var card_container: HBoxContainer = null
var confirm_button: Button = null
var selected_cards: Array = []
var cards_to_discard: int = 0
var max_hand_size: int = 10

# Signals
signal discard_selected(cards: Array)

func _init() -> void:
	# Set layer to be on top
	layer = 100
	# Process input so buttons work
	set_process_input(true)

func _ready() -> void:
	_initialize_ui()

func _initialize_ui() -> void:
	# Don't reinitialize if already done
	if instruction_label:
		return
	
	# Create panel background (full screen overlay)
	panel = Panel.new()
	panel.name = "DiscardPanel"
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create semi-transparent background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Create CenterContainer to center the content
	var center_container = CenterContainer.new()
	center_container.name = "CenterContainer"
	panel.add_child(center_container)
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create main container
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	center_container.add_child(vbox)
	vbox.custom_minimum_size = Vector2(800, 600)
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Title label
	title_label = Label.new()
	title_label.name = "TitleLabel"
	vbox.add_child(title_label)
	title_label.text = "Discard Cards"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 4)
	
	# Instruction label
	instruction_label = Label.new()
	instruction_label.name = "InstructionLabel"
	vbox.add_child(instruction_label)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 24)
	instruction_label.add_theme_color_override("font_color", Color.YELLOW)
	instruction_label.add_theme_color_override("font_outline_color", Color.BLACK)
	instruction_label.add_theme_constant_override("outline_size", 3)
	
	# Card container
	card_container = HBoxContainer.new()
	card_container.name = "CardContainer"
	vbox.add_child(card_container)
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Confirm button
	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	vbox.add_child(confirm_button)
	confirm_button.text = "Confirm Discard"
	confirm_button.custom_minimum_size = Vector2(200, 50)
	confirm_button.add_theme_font_size_override("font_size", 24)
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirm_button.disabled = true
	
	# Start hidden
	visible = false

func open(player_hand: Array, current_hand_size: int, max_size: int) -> void:
	print("[DiscardSelectionUI] open() called with hand size: %d, max: %d" % [current_hand_size, max_size])
	
	# Ensure UI is initialized
	if not instruction_label:
		print("[DiscardSelectionUI] UI not initialized, initializing now...")
		_initialize_ui()
	
	if not instruction_label:
		push_error("[DiscardSelectionUI] Failed to initialize UI!")
		return
	
	max_hand_size = max_size
	selected_cards.clear()
	cards_to_discard = current_hand_size - max_hand_size
	
	print("[DiscardSelectionUI] Cards to discard: %d" % cards_to_discard)
	
	if cards_to_discard <= 0:
		print("[DiscardSelectionUI] No cards need to be discarded")
		discard_selected.emit([])
		return
	
	# Update instruction
	if instruction_label:
		instruction_label.text = "Select %d card(s) to discard (max hand size: %d)" % [cards_to_discard, max_hand_size]
		print("[DiscardSelectionUI] Updated instruction label")
	
	# Clear existing cards
	if card_container:
		for child in card_container.get_children():
			child.queue_free()
		print("[DiscardSelectionUI] Cleared existing cards")
	else:
		push_error("[DiscardSelectionUI] card_container is null!")
		return
	
	# Create card buttons
	print("[DiscardSelectionUI] Creating card buttons for %d cards" % player_hand.size())
	for card in player_hand:
		var card_button = _create_card_button(card)
		if card_button and card_container:
			card_container.add_child(card_button)
		else:
			push_error("[DiscardSelectionUI] Failed to create card button!")
	
	# Show UI - ensure everything is visible
	visible = true
	show()
	print("[DiscardSelectionUI] Set visible = true, visible is now: %s" % str(visible))
	if panel:
		panel.visible = true
		panel.show()
		print("[DiscardSelectionUI] Set panel visible = true, panel.visible: %s" % str(panel.visible))
		# Make sure all children are visible too (recursively)
		_make_node_and_children_visible(panel)
	if confirm_button:
		confirm_button.disabled = true

func _make_node_and_children_visible(node: Node) -> void:
	if node.has_method("show"):
		node.show()
	if "visible" in node:
		node.visible = true
	for child in node.get_children():
		_make_node_and_children_visible(child)
	
	var panel_visible_str = str(panel.visible) if panel else "null"
	print("[DiscardSelectionUI] UI should now be visible. CanvasLayer visible: %s, panel visible: %s" % [str(visible), panel_visible_str])

func _create_card_button(card: Node2D) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(148, 209)  # Card size
	button.toggle_mode = true
	button.text = ""
	button.flat = true
	
	# Store card reference
	button.set_meta("card", card)
	
	# Create SubViewportContainer to properly render the Node2D Card scene
	var viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(viewport_container)
	
	# Create SubViewport for the 2D card
	var viewport = SubViewport.new()
	viewport.size = Vector2i(148, 209)
	viewport.transparent_bg = true
	viewport_container.add_child(viewport)
	
	# Get card data from the card node
	var card_data = null
	if "card_data" in card and card.card_data:
		card_data = card.card_data
	
	if card_data:
		# Instantiate the Card scene
		var card_instance = CARD_SCENE.instantiate()
		card_instance.set_card_data(card_data)
		card_instance.position = Vector2(74, 104.5)  # Center of viewport
		# Make sure card labels are visible
		_make_card_labels_visible(card_instance)
		viewport.add_child(card_instance)
	
	# Connect button
	button.toggled.connect(_on_card_toggled.bind(button))
	
	return button

func _make_card_labels_visible(card_node: Node) -> void:
	# Find all labels and make them visible
	var labels = [
		"CardNumberLabel",
		"CardNameLabel",
		"DescriptionLabel",
		"ElementLabel",
		"RarityLabel"
	]
	
	for label_name in labels:
		var label = card_node.get_node_or_null(label_name)
		if label:
			label.modulate.a = 1.0

func _on_card_toggled(button_pressed: bool, button: Button) -> void:
	var card = button.get_meta("card")
	
	if button_pressed:
		if selected_cards.size() < cards_to_discard:
			selected_cards.append(card)
		else:
			# Deselect if already at max
			button.button_pressed = false
			return
	else:
		selected_cards.erase(card)
	
	# Update confirm button state
	if confirm_button:
		confirm_button.disabled = selected_cards.size() != cards_to_discard
	
	# Update button appearance with overlay
	var overlay = button.get_node_or_null("SelectionOverlay")
	if button_pressed:
		if not overlay:
			overlay = ColorRect.new()
			overlay.name = "SelectionOverlay"
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay.color = Color(1, 0.3, 0.3, 0.4)  # Red tint for selected
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(overlay)
		overlay.visible = true
	else:
		if overlay:
			overlay.visible = false

func _on_confirm_pressed() -> void:
	if selected_cards.size() == cards_to_discard:
		discard_selected.emit(selected_cards)
		close()

func close() -> void:
	visible = false
	selected_cards.clear()
	
	# Clear card container
	if card_container:
		for child in card_container.get_children():
			child.queue_free()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		# Cancel - don't discard anything (but this shouldn't happen as we need to discard)
		# For now, we'll require discarding
		pass
