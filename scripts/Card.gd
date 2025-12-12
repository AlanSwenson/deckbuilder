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
	
	# Update element symbol label
	var element_symbol_label = get_node_or_null("ElementSymbolLabel")
	if element_symbol_label:
		var symbol = _get_element_symbol(card_data.element)
		element_symbol_label.text = symbol
		# Set color based on element
		element_symbol_label.modulate = card_data.get_element_color()
	
	# Update description label
	var description_label = get_node_or_null("DescriptionLabel")
	if description_label:
		description_label.text = card_data.description if card_data.description else ""
	
	# Update damage label (show if damage_value > 0 or has damage_range)
	var damage_label = get_node_or_null("DamageLabel")
	if damage_label:
		var damage_text = ""
		if card_data.damage_value > 0:
			damage_text = str(card_data.damage_value)
		elif card_data.damage_range.x > 0 or card_data.damage_range.y > 0:
			damage_text = str(card_data.damage_range.x) + "-" + str(card_data.damage_range.y)
		damage_label.text = damage_text
		damage_label.visible = damage_text != ""
	
	# Update heal label (show if heal_value > 0 or has heal_range)
	var heal_label = get_node_or_null("HealLabel")
	if heal_label:
		var heal_text = ""
		if card_data.heal_value > 0:
			heal_text = "+" + str(card_data.heal_value)
		elif card_data.heal_range.x > 0 or card_data.heal_range.y > 0:
			heal_text = "+" + str(card_data.heal_range.x) + "-" + str(card_data.heal_range.y)
		heal_label.text = heal_text
		heal_label.visible = heal_text != ""
	
	# Update block label (show if block_value > 0 or has block_range)
	var block_label = get_node_or_null("BlockLabel")
	if block_label:
		var block_text = ""
		if card_data.block_value > 0:
			block_text = str(card_data.block_value)
		elif card_data.block_range.x > 0 or card_data.block_range.y > 0:
			block_text = str(card_data.block_range.x) + "-" + str(card_data.block_range.y)
		block_label.text = block_text
		block_label.visible = block_text != ""
	
	# Update draw label (show if draw_amount > 0)
	var draw_label = get_node_or_null("DrawLabel")
	if draw_label:
		if card_data.draw_amount > 0:
			draw_label.text = "Draw: " + str(card_data.draw_amount)
			draw_label.visible = true
		else:
			draw_label.visible = false
	
	# Update special conditions label
	var special_label = get_node_or_null("SpecialLabel")
	if special_label:
		var special_texts = []
		if card_data.ignores_block:
			special_texts.append("Ignores Block")
		if card_data.bonus_if_facing_empty:
			special_texts.append("Empty Bonus")
		if card_data.bonus_if_adjacent_empty:
			special_texts.append("Adjacent Bonus")
		if card_data.combo_damage_bonus > 0:
			special_texts.append("Combo +" + str(card_data.combo_damage_bonus) + " DMG")
		if card_data.combo_heal_bonus > 0:
			special_texts.append("Combo +" + str(card_data.combo_heal_bonus) + " Heal")
		if card_data.combo_block_bonus > 0:
			special_texts.append("Combo +" + str(card_data.combo_block_bonus) + " Block")
		
		if special_texts.size() > 0:
			special_label.text = "\n".join(special_texts)
			special_label.visible = true
		else:
			special_label.visible = false
	
	# Update card number label to show card name for now (can change later)
	var number_label = get_node_or_null("CardNumberLabel")
	if number_label:
		# Keep the number label for testing/identification if needed
		pass

# Get the symbol for each element type
func _get_element_symbol(element_type: CardData.ElementType) -> String:
	match element_type:
		CardData.ElementType.SULFUR:
			return "🔥"  # Fire
		CardData.ElementType.MERCURY:
			return "💧"  # Water/Liquid
		CardData.ElementType.SALT:
			return "⛰️"  # Earth/Mountain
		CardData.ElementType.VITAE:
			return "🌿"  # Life/Plant
		CardData.ElementType.AETHER:
			return "⭐"  # Spirit/Star
	return "?"
