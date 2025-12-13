extends Resource
class_name SaveData

@export var slot_number: int = 0
@export var player_name: String = "New Game"
@export var total_runs: int = 0
@export var cards_collected: int = 0
@export var current_act: int = 1
@export var play_time_seconds: float = 0.0

# Card collection (array of card names or IDs)
@export var card_collection: Array[String] = []

# Add more data as needed
@export var ingredients: Dictionary = {}
@export var recipes_unlocked: Array[String] = []

func _init():
	pass

# Check if this save slot has data
func is_empty() -> bool:
	return total_runs == 0

# Get display text for save slot button
func get_display_text() -> String:
	if is_empty():
		return "EMPTY SLOT"
	else:
		return "Slot %d - %d Runs - Act %d\n%d Cards Collected" % [slot_number, total_runs, current_act, cards_collected]