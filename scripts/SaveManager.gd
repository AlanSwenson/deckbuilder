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
	
	if ResourceLoader.exists(file_path):
		var save_data = ResourceLoader.load(file_path) as SaveData
		if save_data:
			current_save_slot = slot
			current_save_data = save_data
			return save_data
	
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
	
	var file_path = SAVE_DIR + (SAVE_FILE_TEMPLATE % current_save_slot)
	var error = ResourceSaver.save(current_save_data, file_path)
	
	if error != OK:
		push_error("Failed to save game: %d" % error)
	else:
		print("Game saved to slot %d" % current_save_slot)

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
