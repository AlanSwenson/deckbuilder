extends Node2D

var overlapping_cards: Array[Area2D] = []

func _ready() -> void:
	var area = get_node("Area2D")
	if area:
		# Connect signals to detect when cards enter/exit the slot
		area.area_entered.connect(_on_area_entered)
		area.area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	# Check if the area belongs to a card
	var card = area.get_parent()
	if card and card.name.begins_with("Card"):
		if area not in overlapping_cards:
			overlapping_cards.append(area)
			print("[CardSlot] Card entered slot: ", card.name)

func _on_area_exited(area: Area2D) -> void:
	var card = area.get_parent()
	if card and card.name.begins_with("Card"):
		if area in overlapping_cards:
			overlapping_cards.erase(area)
			print("[CardSlot] Card exited slot: ", card.name)

# Check if a specific card is overlapping this slot
func is_card_overlapping(card: Node2D) -> bool:
	var card_area = card.get_node_or_null("Area2D")
	if card_area and card_area in overlapping_cards:
		return true
	return false

# Get the distance from a global point to this slot's center
func get_distance_to_point(global_point: Vector2) -> float:
	return global_position.distance_to(global_point)

# Snap a card to this slot's position
func snap_card(card: Node2D) -> void:
	if card:
		card.global_position = global_position
		print("[CardSlot] Snapped card to slot: ", card.name, " at position: ", global_position)
