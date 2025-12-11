extends Node2D

var hand_position
var card_data: CardData = null  # The card data for this card

func set_card_number(number: int) -> void:
	var label = get_node_or_null("CardNumberLabel")
	if label:
		label.text = str(number)

# Set the card data and update the display
func set_card_data(data: CardData) -> void:
	card_data = data
	# Try to update immediately if in tree, otherwise defer
	if is_inside_tree():
		update_card_display()
	else:
		# If not in tree yet, wait and then update
		call_deferred("update_card_display")

# Update the card's visual display based on card_data
func update_card_display() -> void:
	if not card_data:
		print("[Card] ERROR: No card_data to display for card ", name)
		return
	
	# Update card name label
	var name_label = get_node_or_null("CardNameLabel")
	if name_label:
		name_label.text = card_data.card_name
		print("[Card] Set card name to: ", card_data.card_name, " for card ", name)
	else:
		print("[Card] ERROR: CardNameLabel not found for card ", name)
	
	# Update card number label to show card name for now (can change later)
	var number_label = get_node_or_null("CardNumberLabel")
	if number_label:
		# Keep the number label for testing/identification if needed
		pass
