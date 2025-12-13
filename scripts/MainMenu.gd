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
		# Create starter deck, etc.
	else:
		print("[MainMenu] Loading existing save from slot %d" % slot)
	
	# Save immediately to create the file
	SaveManager.save_game()
	
	# Load the game scene
	print("[MainMenu] Changing scene to: %s" % GAME_SCENE)
	var error = get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("[MainMenu] Failed to change scene: %d" % error)

func _on_quit_pressed():
	get_tree().quit()
