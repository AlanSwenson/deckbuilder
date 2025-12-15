extends Control

@onready var save_slot_1 = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/SaveSlot1
@onready var save_slot_2 = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/SaveSlot2
@onready var save_slot_3 = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/SaveSlot3
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton

# Reference to your combat/game scene
const GAME_SCENE = "res://main.tscn"

func _ready():
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
	
	# Update button texts
	_update_save_slot_displays()

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
	if save_slot_2:
		save_slot_2.text = save2.get_display_text()
	if save_slot_3:
		save_slot_3.text = save3.get_display_text()

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
		
		# Create starter deck and save it
		var starter_deck = ExampleCards.create_starter_deck()
		save_data.set_current_deck(starter_deck)
		print("[MainMenu] Created starter deck with %d cards" % starter_deck.size())
		print("[MainMenu] Deck saved - first card: %s (rarity: %d)" % [starter_deck[0].card_name if starter_deck.size() > 0 else "none", starter_deck[0].rarity if starter_deck.size() > 0 else -1])
	else:
		print("[MainMenu] Loading existing save from slot %d" % slot)
		print("[MainMenu] Existing deck has %d cards" % save_data.current_deck.size())
		if save_data.current_deck.size() > 0:
			var first_card_dict = save_data.current_deck[0]
			print("[MainMenu] First card in save: %s (rarity: %d)" % [first_card_dict.get("card_name", "unknown"), first_card_dict.get("rarity", -1)])
		
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

func _on_quit_pressed():
	get_tree().quit()
