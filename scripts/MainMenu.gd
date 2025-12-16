extends Control

var save_slot_1: Button
var save_slot_2: Button
var save_slot_3: Button
var quit_button: Button
var delete_buttons: Array[Button] = []

# Reference to your combat/game scene
const GAME_SCENE = "res://main.tscn"

func _ready():
	# Get node references
	var vbox = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer
	save_slot_1 = vbox.get_node("SaveSlot1Container/SaveSlot1")
	save_slot_2 = vbox.get_node("SaveSlot2Container/SaveSlot2")
	save_slot_3 = vbox.get_node("SaveSlot3Container/SaveSlot3")
	quit_button = $CenterContainer/VBoxContainer/QuitButton
	
	# Check if buttons exist
	if not save_slot_1:
		push_error("[MainMenu] save_slot_1 is null!")
	if not save_slot_2:
		push_error("[MainMenu] save_slot_2 is null!")
	if not save_slot_3:
		push_error("[MainMenu] save_slot_3 is null!")
	
	# Connect save slot buttons
	if save_slot_1:
		save_slot_1.pressed.connect(_on_save_slot_pressed.bind(1))
		print("[MainMenu] Connected save_slot_1")
	else:
		push_error("[MainMenu] Cannot connect save_slot_1 - button is null")
	
	if save_slot_2:
		save_slot_2.pressed.connect(_on_save_slot_pressed.bind(2))
		print("[MainMenu] Connected save_slot_2")
	else:
		push_error("[MainMenu] Cannot connect save_slot_2 - button is null")
	
	if save_slot_3:
		save_slot_3.pressed.connect(_on_save_slot_pressed.bind(3))
		print("[MainMenu] Connected save_slot_3")
	else:
		push_error("[MainMenu] Cannot connect save_slot_3 - button is null")
	
	# Connect quit button
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		print("[MainMenu] Connected quit_button")
	else:
		push_error("[MainMenu] quit_button is null!")
	
	# Create delete buttons for each save slot
	_create_delete_buttons()
	
	# Update button texts
	_update_save_slot_displays()

func _create_delete_buttons() -> void:
	# Create delete buttons for each save slot
	var slots = [save_slot_1, save_slot_2, save_slot_3]
	
	for i in range(slots.size()):
		var slot_button = slots[i]
		if not slot_button:
			continue
		
		# Get the container (HBoxContainer) that holds the save slot button
		var container = slot_button.get_parent()
		if not container:
			continue
		
		# Create delete button
		var delete_button = Button.new()
		delete_button.text = "×"
		delete_button.custom_minimum_size = Vector2(30, 30)
		delete_button.name = "DeleteButton%d" % (i + 1)
		
		# Style the button
		delete_button.add_theme_font_size_override("font_size", 20)
		delete_button.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		
		# Connect the button
		delete_button.pressed.connect(_confirm_delete_save_slot.bind(i + 1))
		
		# Add to container (HBoxContainer) - it will be positioned next to the save slot
		container.add_child(delete_button)
		delete_buttons.append(delete_button)
		
		# Initially hide if slot is empty
		delete_button.visible = false

func _update_save_slot_displays():
	# Check if SaveManager exists
	if not SaveManager:
		push_error("[MainMenu] SaveManager is not available!")
		return
	
	# Load save data for each slot and update button text
	var save1 = SaveManager.peek_save(1)
	var save2 = SaveManager.peek_save(2)
	var save3 = SaveManager.peek_save(3)
	
	if save_slot_1:
		save_slot_1.text = save1.get_display_text()
		# Show/hide delete button based on whether save exists
		if delete_buttons.size() > 0:
			delete_buttons[0].visible = SaveManager.save_exists(1)
	
	if save_slot_2:
		save_slot_2.text = save2.get_display_text()
		if delete_buttons.size() > 1:
			delete_buttons[1].visible = SaveManager.save_exists(2)
	
	if save_slot_3:
		save_slot_3.text = save3.get_display_text()
		if delete_buttons.size() > 2:
			delete_buttons[2].visible = SaveManager.save_exists(3)

func _on_save_slot_pressed(slot: int):
	print("[MainMenu] Selected save slot: %d" % slot)
	
	# Check if SaveManager exists
	if not SaveManager:
		push_error("[MainMenu] SaveManager is not available!")
		return
	
	# Load or create save
	var save_data = SaveManager.load_save(slot)
	
	if not save_data:
		push_error("[MainMenu] Failed to load/create save data for slot %d" % slot)
		return
	
	if save_data.is_empty():
		print("[MainMenu] Starting new game in slot %d" % slot)
		# Initialize new game data
		save_data.total_runs = 0
		save_data.cards_collected = 0
		save_data.current_act = 1
		save_data.player_name = "Save Slot %d" % slot  # Set default name
		
		# Clear any previous match state
		save_data.clear_match_state()
		
		# Create starter collection and save it
		var starter_collection = ExampleCards.create_starter_collection()
		# Add all cards to collection
		for card in starter_collection:
			save_data.add_card_to_collection(card)
		
		# Create a default deck from the collection (can be changed later)
		# For now, use the first 30 cards as the default deck
		var default_deck = starter_collection.slice(0, mini(30, starter_collection.size()))
		save_data.set_current_deck(default_deck)
		
		# Also save it as a named deck
		save_data.decks["Default Deck"] = []
		for card in default_deck:
			save_data.decks["Default Deck"].append(card.to_save_dict())
		save_data.current_deck_name = "Default Deck"
		
		print("[MainMenu] Created starter collection with %d cards" % starter_collection.size())
		print("[MainMenu] Created default deck with %d cards" % default_deck.size())
		if starter_collection.size() > 0:
			var first_card = starter_collection[0]
			var card_name = first_card.card_name
			var card_rarity = first_card.rarity
			print("[MainMenu] First card: %s (rarity: %d)" % [card_name, card_rarity])
	else:
		print("[MainMenu] Loading existing save from slot %d" % slot)
		print("[MainMenu] Existing deck has %d cards" % save_data.current_deck.size())
		if save_data.current_deck.size() > 0:
			var first_card_dict = save_data.current_deck[0]
			var card_name = first_card_dict.get("card_name", "unknown")
			var card_rarity = first_card_dict.get("rarity", -1)
			print("[MainMenu] First card in save: %s (rarity: %d)" % [card_name, card_rarity])
		
		# Check if there's an in-progress match
		if save_data.has_match_to_resume():
			print("[MainMenu] Found in-progress match - will resume game state")
	
	# Save immediately to create/persist the file
	SaveManager.save_game()
	
	# Update the display to show the new save info
	_update_save_slot_displays()
	
	# Load the game scene
	print("[MainMenu] Changing scene to: %s" % GAME_SCENE)
	var error = get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("[MainMenu] Failed to change scene: %d" % error)

func _confirm_delete_save_slot(slot: int) -> void:
	# Create confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Delete save slot %d?\n\nThis action cannot be undone." % slot
	dialog.title = "Confirm Delete"
	
	# Get save info for display
	if SaveManager:
		var save_data = SaveManager.peek_save(slot)
		if save_data and not save_data.is_empty():
			var msg = ("Delete save slot %d?\n\nPlayer: %s\nRuns: %d\n\n" +
				"This action cannot be undone.")
			var player_name = save_data.player_name
			var total_runs = save_data.total_runs
			dialog.dialog_text = msg % [slot, player_name, total_runs]
	
	# Connect confirmed signal
	dialog.confirmed.connect(_delete_save_slot.bind(slot))
	
	# Add to scene and show
	add_child(dialog)
	dialog.popup_centered()

func _delete_save_slot(slot: int) -> void:
	if not SaveManager:
		push_error("[MainMenu] SaveManager is not available!")
		return
	
	# Delete the save
	SaveManager.delete_save(slot)
	print("[MainMenu] Deleted save slot %d" % slot)
	
	# Update the display
	_update_save_slot_displays()

func _on_quit_pressed():
	get_tree().quit()
