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
	
	# Update description label - use generated description from abilities
	var description_label = get_node_or_null("DescriptionLabel")
	if description_label:
		# Use the stored description or generate from abilities
		var desc = card_data.description if card_data.description != "" else card_data.generate_description()
		description_label.text = desc
	
	# Update damage label using new ability system
	var damage_label = get_node_or_null("DamageLabel")
	if damage_label:
		var damage = card_data.get_total_damage()
		if damage > 0:
			damage_label.text = str(damage)
			damage_label.visible = true
		else:
			damage_label.visible = false
	
	# Update heal label using new ability system
	var heal_label = get_node_or_null("HealLabel")
	if heal_label:
		var heal = card_data.get_total_heal()
		if heal > 0:
			heal_label.text = "+" + str(heal)
			heal_label.visible = true
		else:
			heal_label.visible = false
	
	# Update block label using new ability system
	var block_label = get_node_or_null("BlockLabel")
	if block_label:
		var block = card_data.get_total_block()
		if block > 0:
			block_label.text = str(block)
			block_label.visible = true
		else:
			block_label.visible = false
	
	# Update draw label using new ability system
	var draw_label = get_node_or_null("DrawLabel")
	if draw_label:
		var draw = card_data.get_total_draw()
		if draw > 0:
			draw_label.text = "Draw: " + str(draw)
			draw_label.visible = true
		else:
			draw_label.visible = false
	
	# Update special conditions label using new ability system
	var special_label = get_node_or_null("SpecialLabel")
	if special_label:
		var special_texts = []
		
		# Check for ignores_block ability
		if card_data.ignores_block():
			special_texts.append("Ignores Block")
		
		# Check for combo damage ability
		var combo_dmg = card_data.get_combo_damage()
		if combo_dmg > 0:
			special_texts.append("Combo +" + str(combo_dmg) + " DMG")
		
		if special_texts.size() > 0:
			special_label.text = "\n".join(special_texts)
			special_label.visible = true
		else:
			special_label.visible = false
	
	# Update rarity indicator (if you have one)
	var rarity_label = get_node_or_null("RarityLabel")
	if rarity_label:
		rarity_label.text = card_data.get_rarity_name()
		rarity_label.modulate = card_data.get_rarity_color()
	
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
