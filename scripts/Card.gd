extends Node2D

var hand_position
var card_data: CardData = null  # The card data for this card
var is_hovered: bool = false
var shadow_sprite: Sprite2D = null

# Cache the shadow texture to avoid duplicate loads
static var _shadow_texture_cache: Texture2D = null

func _ready() -> void:
	# Connect Area2D signals for hover detection
	var area = get_node_or_null("Area2D")
	if area:
		area.mouse_entered.connect(_on_mouse_entered)
		area.mouse_exited.connect(_on_mouse_exited)
		area.input_event.connect(_on_area_input_event)
	
	# Create drop shadow sprite (defer to ensure card image is ready)
	call_deferred("_create_drop_shadow")

func _get_shadow_texture() -> Texture2D:
	# Cache the texture to avoid duplicate loads
	if not _shadow_texture_cache:
		_shadow_texture_cache = load("res://assets/art/cards/CardShadow.png")
	return _shadow_texture_cache

func _create_drop_shadow() -> void:
	# Create shadow sprite if it doesn't exist
	if not shadow_sprite:
		shadow_sprite = Sprite2D.new()
		shadow_sprite.name = "DropShadow"
		shadow_sprite.z_index = -10  # Behind everything
		shadow_sprite.modulate = Color(1, 1, 1, 0)  # Start invisible
		shadow_sprite.offset = Vector2(4, 4)  # Offset for drop shadow effect
		add_child(shadow_sprite)
	
	# Load and set the CardShadow texture
	var shadow_texture = _get_shadow_texture()
	if shadow_texture:
		shadow_sprite.texture = shadow_texture

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_shadow()

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_shadow()

func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# Additional input handling if needed
	pass

func _update_shadow() -> void:
	if shadow_sprite:
		shadow_sprite.visible = is_hovered
		# Animate shadow appearance at 50% opacity
		if is_hovered:
			var tween = create_tween()
			tween.tween_property(shadow_sprite, "modulate:a", 0.5, 0.1)
		else:
			var tween = create_tween()
			tween.tween_property(shadow_sprite, "modulate:a", 0.0, 0.1)

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
	
	# Ensure shadow sprite has the CardShadow texture
	if shadow_sprite and not shadow_sprite.texture:
		var shadow_texture = _get_shadow_texture()
		if shadow_texture:
			shadow_sprite.texture = shadow_texture
	
	# Reset CardImage modulate to white (no tint) since we removed background coloring
	var card_image = get_node_or_null("CardImage")
	if card_image:
		card_image.modulate = Color.WHITE

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
