extends Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE_TEMPLATE = "save_slot_%d.tres"

var current_save_slot: int = -1
var current_save_data: SaveData = null

func _ready():
	# Ensure save directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

# Load save data from slot number
func load_save(slot: int) -> SaveData:
	var file_path = SAVE_DIR + (SAVE_FILE_TEMPLATE % slot)
	print("[SaveManager] Attempting to load save from: %s" % file_path)
	
	if ResourceLoader.exists(file_path):
		print("[SaveManager] Save file exists, loading...")
		var save_data = ResourceLoader.load(file_path) as SaveData
		if save_data:
			current_save_slot = slot
			current_save_data = save_data
			print("[SaveManager] Loaded save - Deck size: %d, Collection size: %d" % [save_data.current_deck.size(), save_data.card_collection.size()])
			return save_data
		else:
			push_error("[SaveManager] Failed to load save data from %s" % file_path)
	else:
		print("[SaveManager] Save file does not exist, creating new save")
	
	# If no save exists, create new empty save
	return create_new_save(slot)

# Create a new empty save
func create_new_save(slot: int) -> SaveData:
	var save_data = SaveData.new()
	save_data.slot_number = slot
	current_save_slot = slot
	current_save_data = save_data
	return save_data

# Save current data to disk
func save_game() -> void:
	if current_save_data == null or current_save_slot == -1:
		push_error("No active save to save!")
		return
	
	# Ensure save directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	
	var file_path = SAVE_DIR + (SAVE_FILE_TEMPLATE % current_save_slot)
	print("[SaveManager] Saving to: %s" % file_path)
	print("[SaveManager] Save data - Deck size: %d, Collection size: %d" % [current_save_data.current_deck.size(), current_save_data.card_collection.size()])
	
	var error = ResourceSaver.save(current_save_data, file_path)
	
	if error != OK:
		push_error("Failed to save game: %d" % error)
	else:
		print("[SaveManager] Game saved successfully to slot %d" % current_save_slot)
		# Verify the file was created
		if ResourceLoader.exists(file_path):
			print("[SaveManager] Save file verified: %s exists" % file_path)
		else:
			push_error("[SaveManager] WARNING: Save file not found after save operation!")

# Check if a save exists in slot
func save_exists(slot: int) -> bool:
	var file_path = SAVE_DIR + (SAVE_FILE_TEMPLATE % slot)
	return ResourceLoader.exists(file_path)

# Get save data without loading it (for preview)
func peek_save(slot: int) -> SaveData:
	var file_path = SAVE_DIR + (SAVE_FILE_TEMPLATE % slot)
	
	if ResourceLoader.exists(file_path):
		return ResourceLoader.load(file_path) as SaveData
	else:
		var empty_save = SaveData.new()
		empty_save.slot_number = slot
		return empty_save

# Delete a save slot
func delete_save(slot: int) -> void:
	var file_path = SAVE_DIR + (SAVE_FILE_TEMPLATE % slot)
	var dir = DirAccess.open(SAVE_DIR)
	if dir.file_exists(file_path):
		dir.remove(file_path)

# Autosave the current game state
func autosave_game_state() -> void:
	if current_save_data == null or current_save_slot == -1:
		return
	
	var game_state_saver = GameStateSaver.new()
	add_child(game_state_saver)
	game_state_saver.save_game_state(current_save_data)
	save_game()  # Persist to disk
	game_state_saver.queue_free()
	print("[SaveManager] Autosaved game state")

# Load saved game state if it exists
func load_saved_game_state() -> bool:
	if current_save_data == null or not current_save_data.has_match_to_resume():
		return false
	
	var game_state_saver = GameStateSaver.new()
	add_child(game_state_saver)
	var success = await game_state_saver.load_game_state(current_save_data)
	game_state_saver.queue_free()
	
	if success:
		print("[SaveManager] Loaded saved game state")
	else:
		print("[SaveManager] Failed to load game state")
	
	return success
