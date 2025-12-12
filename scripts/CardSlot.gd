extends Node2D

var overlapping_cards: Array[Area2D] = []
var current_card: Node2D = null  # Track which card is currently in this slot

func _ready() -> void:
	var area = get_node("Area2D")
	if area:
		# Connect signals to detect when cards enter/exit the slot
		area.area_entered.connect(_on_area_entered)
		area.area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	# Check if the area belongs to a card (player or enemy)
	var card = area.get_parent()
	if card and (card.name.begins_with("Card") or card.name.begins_with("EnemyCard")):
		# Don't track cards that are being added to hand
		if card.has_meta("adding_to_hand"):
			return
		if area not in overlapping_cards:
			overlapping_cards.append(area)
			# Logging removed per user request

func _on_area_exited(area: Area2D) -> void:
	var card = area.get_parent()
	if card and (card.name.begins_with("Card") or card.name.begins_with("EnemyCard")):
		# Don't track cards that are being added to hand
		if card.has_meta("adding_to_hand"):
			return
		if area in overlapping_cards:
			overlapping_cards.erase(area)
			# Logging removed per user request

# Check if a specific card is overlapping this slot
func is_card_overlapping(card: Node2D) -> bool:
	var card_area = card.get_node_or_null("Area2D")
	if card_area and card_area in overlapping_cards:
		return true
	return false

# Get the distance from a global point to this slot's center
func get_distance_to_point(global_point: Vector2) -> float:
	return global_position.distance_to(global_point)

# Snap a card to this slot's position, swapping if slot is occupied
# Returns the card that was previously in this slot (if any), or null if slot was empty
func snap_card(card: Node2D) -> Node2D:
	if not card:
		print("[CardSlot] snap_card() called with null card")
		return null
	
	print("[CardSlot] snap_card() called for ", card.name, " to slot ", name)
	
	# Don't snap cards that are being added to hand (they're animating to hand position)
	if card.has_meta("adding_to_hand"):
		print("[CardSlot] BLOCKED snap - card is being added to hand: ", card.name, " | Has flag: ", card.has_meta("adding_to_hand"))
		return null
	
	# Check monitoring status
	var card_area = card.get_node_or_null("Area2D")
	if card_area:
		print("[CardSlot] Card ", card.name, " monitoring status: ", card_area.monitoring)
	
	var previously_occupied_card = current_card
	
	# If there's already a card in this slot (and it's different), we need to swap
	if current_card and current_card != card:
		# Clear the slot reference from the old card (will be handled by caller)
		_clear_slot_reference(current_card)
		
		# Move the new card to this slot
		card.global_position = global_position
		
		print(
			"[CardSlot] Swapping: ",
			card.name,
			" into slot ",
			name,
			", ",
			previously_occupied_card.name,
			" will be moved"
		)
	else:
		# Slot is empty, just snap the card
		card.global_position = global_position
		print(
			"[CardSlot] Snapped card to slot: ",
			card.name,
			" at position: ",
			global_position
		)
	
	# Update the slot's current card reference
	current_card = card
	_set_slot_reference(card)
	
	# Set a reasonable z_index for cards in slots (lower than dragged cards)
	# This ensures slotted cards appear below dragged cards
	# But don't override z_index if the card is currently being dragged
	# Check if card is being dragged by looking for InputManager
	var is_card_being_dragged = false
	var main_node = get_tree().current_scene
	if main_node:
		var input_manager = main_node.get_node_or_null("InputManager")
		if input_manager and input_manager.has_method("get_dragged_card"):
			var is_dragging = false
			if "is_dragging" in input_manager:
				is_dragging = input_manager.is_dragging
			var dragged_card_ref = input_manager.get_dragged_card()
			if is_dragging and card == dragged_card_ref:
				is_card_being_dragged = true
	
	# Only set z_index if card is not being dragged (or check high z_index as backup)
	if not is_card_being_dragged and card.z_index < 500:
		# Set z_index based on card number so higher numbers appear on top
		# Base z_index for slots is 100, add card number as offset
		var card_number = 1  # Default
		if card.has_meta("card_number"):
			card_number = card.get_meta("card_number")
		else:
			# Fallback: try to get from CardNumberLabel if available
			var label = card.get_node_or_null("CardNumberLabel")
			if label and label.text.is_valid_int():
				card_number = label.text.to_int()
		
		# Higher card numbers get higher z_index (card 10 appears above card 1)
		card.z_index = 100 + card_number
	
	return previously_occupied_card

# Set a reference to this slot on the card (using meta data)
func _set_slot_reference(card: Node2D) -> void:
	if card:
		card.set_meta("current_slot", self)

# Clear the slot reference from a card
func _clear_slot_reference(card: Node2D) -> void:
	if card and card.has_meta("current_slot"):
		var old_slot = card.get_meta("current_slot")
		if old_slot == self:
			card.remove_meta("current_slot")

# Remove a card from this slot (when card is moved elsewhere)
func remove_card(card: Node2D) -> void:
	if current_card == card:
		current_card = null
		_clear_slot_reference(card)
		print("[CardSlot] Removed card from slot: ", card.name)

# Get the card currently in this slot
func get_current_card() -> Node2D:
	return current_card
