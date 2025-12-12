extends Node
class_name DamageCalculator

# References (set by TurnLogic)
var game_state: Node2D = null

func setup(game_state_ref: Node2D) -> void:
	game_state = game_state_ref

# Calculate total damage from player cards
func calculate_player_damage() -> int:
	var total_damage = 0
	var main_node = get_tree().current_scene
	var player_slots = []
	_find_player_slots(main_node, player_slots)
	
	for slot in player_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card):
			var card_data = null
			if "card_data" in current_card:
				card_data = current_card.card_data
			
			if card_data:
				var damage = 0
				if card_data.damage_value > 0:
					damage = card_data.damage_value
				elif card_data.damage_range.x > 0 or card_data.damage_range.y > 0:
					damage = randi_range(card_data.damage_range.x, card_data.damage_range.y)
				
				total_damage += damage
				print("[DamageCalculator] Player card ", card_data.card_name, " deals ", damage, " damage")
	
	print("[DamageCalculator] Total player damage: ", total_damage)
	return total_damage

# Calculate total damage from enemy cards
func calculate_enemy_damage() -> int:
	var total_damage = 0
	var main_node = get_tree().current_scene
	var enemy_slots = []
	_find_enemy_slots(main_node, enemy_slots)
	
	for slot in enemy_slots:
		var current_card = null
		if "current_card" in slot:
			current_card = slot.current_card
		elif slot.has_method("get_current_card"):
			current_card = slot.get_current_card()
		
		if current_card and is_instance_valid(current_card):
			var card_data = null
			if "card_data" in current_card:
				card_data = current_card.card_data
			
			if card_data:
				var damage = 0
				if card_data.damage_value > 0:
					damage = card_data.damage_value
				elif card_data.damage_range.x > 0 or card_data.damage_range.y > 0:
					damage = randi_range(card_data.damage_range.x, card_data.damage_range.y)
				
				total_damage += damage
				print("[DamageCalculator] Enemy card ", card_data.card_name, " deals ", damage, " damage")
	
	print("[DamageCalculator] Total enemy damage: ", total_damage)
	return total_damage

# Resolve turn slot by slot (1-5)
func resolve_turn_slot_by_slot() -> void:
	# This function uses await, so it's effectively async
	if not game_state:
		return
	
	var main_node = get_tree().current_scene
	var player_slots = []
	var enemy_slots = []
	_find_player_slots(main_node, player_slots)
	_find_enemy_slots(main_node, enemy_slots)
	
	# Sort slots by number (1-5)
	player_slots.sort_custom(func(a, b): return _get_slot_number(a) < _get_slot_number(b))
	enemy_slots.sort_custom(func(a, b): return _get_slot_number(a) < _get_slot_number(b))
	
	print("[DamageCalculator] Resolving turn slot by slot...")
	
	# Resolve each slot (1-5)
	for slot_index in range(1, 6):  # Slots 1-5
		# Check if game ended
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[DamageCalculator] Game ended, stopping slot resolution at slot ", slot_index)
				return
		
		print("[DamageCalculator] ===== Resolving Slot ", slot_index, " =====")
		
		# Find player and enemy slots for this slot number
		var player_slot = _find_slot_by_number(player_slots, slot_index)
		var enemy_slot = _find_slot_by_number(enemy_slots, slot_index)
		
		# Get cards from slots
		var player_card = null
		var player_card_data = null
		if player_slot:
			player_card = _get_card_from_slot(player_slot)
			if player_card and is_instance_valid(player_card):
				if "card_data" in player_card:
					player_card_data = player_card.card_data
		
		# Raise player card to show it's being evaluated
		var player_card_original_position = null
		if player_card and is_instance_valid(player_card):
			# Set flag to prevent auto-snapping during animation
			player_card.set_meta("evaluating_slot", true)
			player_card_original_position = player_card.global_position
			# Raise card by 30 pixels
			var raised_position = player_card.global_position + Vector2(0, -30)
			var raise_tween = get_tree().create_tween()
			raise_tween.tween_property(player_card, "global_position", raised_position, 0.2)
			await raise_tween.finished
		
		var enemy_card = null
		var enemy_card_data = null
		if enemy_slot:
			enemy_card = _get_card_from_slot(enemy_slot)
			if enemy_card and is_instance_valid(enemy_card):
				if "card_data" in enemy_card:
					enemy_card_data = enemy_card.card_data
		
		# Resolve player card effects
		var player_damage = 0
		var player_heal = 0
		var player_block = 0
		if player_card_data:
			# Calculate damage
			if player_card_data.damage_value > 0:
				player_damage = player_card_data.damage_value
			elif player_card_data.damage_range.x > 0 or player_card_data.damage_range.y > 0:
				player_damage = randi_range(player_card_data.damage_range.x, player_card_data.damage_range.y)
			
			# Get healing
			if player_card_data.heal_value > 0:
				player_heal = player_card_data.heal_value
			
			# Get block
			if player_card_data.block_value > 0:
				player_block = player_card_data.block_value
			
			if player_damage > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Player card ", player_card_data.card_name, " deals ", player_damage, " damage")
			if player_heal > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Player card ", player_card_data.card_name, " heals ", player_heal)
			if player_block > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Player card ", player_card_data.card_name, " blocks ", player_block)
		
		# Resolve enemy card effects
		var enemy_damage = 0
		var enemy_heal = 0
		var enemy_block = 0
		if enemy_card_data:
			# Calculate damage
			if enemy_card_data.damage_value > 0:
				enemy_damage = enemy_card_data.damage_value
			elif enemy_card_data.damage_range.x > 0 or enemy_card_data.damage_range.y > 0:
				enemy_damage = randi_range(enemy_card_data.damage_range.x, enemy_card_data.damage_range.y)
			
			# Get healing
			if enemy_card_data.heal_value > 0:
				enemy_heal = enemy_card_data.heal_value
			
			# Get block
			if enemy_card_data.block_value > 0:
				enemy_block = enemy_card_data.block_value
			
			if enemy_damage > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Enemy card ", enemy_card_data.card_name, " deals ", enemy_damage, " damage")
			if enemy_heal > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Enemy card ", enemy_card_data.card_name, " heals ", enemy_heal)
			if enemy_block > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Enemy card ", enemy_card_data.card_name, " blocks ", enemy_block)
		
		# Calculate midpoint between player and enemy cards for displaying results
		var display_position = Vector2(0, 0)
		if player_card and is_instance_valid(player_card) and enemy_card and is_instance_valid(enemy_card):
			# Use global positions to calculate midpoint
			var player_pos = player_card.global_position
			var enemy_pos = enemy_card.global_position
			display_position = (player_pos + enemy_pos) / 2
		elif player_card and is_instance_valid(player_card):
			display_position = player_card.global_position + Vector2(0, -50)
		elif enemy_card and is_instance_valid(enemy_card):
			display_position = enemy_card.global_position + Vector2(0, 50)
		else:
			# Fallback to slot position if no cards
			if player_slot:
				display_position = player_slot.global_position
			elif enemy_slot:
				display_position = enemy_slot.global_position
		
		# Track number of effects to offset multiple numbers
		var effect_count = 0
		var numbers_to_show = []
		
		# Apply damage (with block reduction if applicable)
		# Player damage to enemy
		if player_damage > 0:
			var final_player_damage = player_damage
			# Check if enemy card ignores block
			if not enemy_card_data or not enemy_card_data.ignores_block:
				final_player_damage = max(0, player_damage - enemy_block)
				if enemy_block > 0 and final_player_damage < player_damage:
					print("[DamageCalculator] Slot ", slot_index, ": Enemy block reduced damage from ", player_damage, " to ", final_player_damage)
			
			if final_player_damage > 0 and game_state.has_method("damage_enemy"):
				game_state.damage_enemy(final_player_damage)
				# Queue damage number to show
				var offset_pos = display_position + Vector2(effect_count * 60 - 30, 0)
				numbers_to_show.append({"position": offset_pos, "text": "-" + str(final_player_damage), "color": Color.RED})
				effect_count += 1
		
		# Enemy damage to player
		if enemy_damage > 0:
			var final_enemy_damage = enemy_damage
			# Check if player card ignores block
			if not player_card_data or not player_card_data.ignores_block:
				final_enemy_damage = max(0, enemy_damage - player_block)
				if player_block > 0 and final_enemy_damage < enemy_damage:
					print("[DamageCalculator] Slot ", slot_index, ": Player block reduced damage from ", enemy_damage, " to ", final_enemy_damage)
			
			if final_enemy_damage > 0 and game_state.has_method("damage_player"):
				game_state.damage_player(final_enemy_damage)
				# Queue damage number to show
				var offset_pos = display_position + Vector2(effect_count * 60 - 30, 0)
				numbers_to_show.append({"position": offset_pos, "text": "-" + str(final_enemy_damage), "color": Color.RED})
				effect_count += 1
		
		# Apply healing
		if player_heal > 0 and game_state.has_method("heal_player"):
			game_state.heal_player(player_heal)
			# Queue heal number to show
			var offset_pos = display_position + Vector2(effect_count * 60 - 30, 0)
			numbers_to_show.append({"position": offset_pos, "text": "+" + str(player_heal), "color": Color.GREEN})
			effect_count += 1
		
		if enemy_heal > 0 and game_state.has_method("heal_enemy"):
			game_state.heal_enemy(enemy_heal)
			# Queue heal number to show
			var offset_pos = display_position + Vector2(effect_count * 60 - 30, 0)
			numbers_to_show.append({"position": offset_pos, "text": "+" + str(enemy_heal), "color": Color.GREEN})
			effect_count += 1
		
		# Show all numbers at once (non-blocking)
		for number_data in numbers_to_show:
			_show_rising_number(number_data.position, number_data.text, number_data.color)
		
		# Lower player card back to original position
		if player_card and is_instance_valid(player_card) and player_card_original_position != null:
			var lower_tween = get_tree().create_tween()
			lower_tween.tween_property(player_card, "global_position", player_card_original_position, 0.2)
			await lower_tween.finished
			# Remove flag after animation completes
			if player_card and is_instance_valid(player_card) and player_card.has_meta("evaluating_slot"):
				player_card.remove_meta("evaluating_slot")
		
		# HP/block displays are updated automatically by GameState methods
		# Add a small delay for visual feedback
		await get_tree().create_timer(0.2).timeout
		
		# Check if game ended after this slot
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[DamageCalculator] Game ended after slot ", slot_index, " resolution")
				return

# Helper to get slot number from slot name (e.g., "PlayerSlot3" -> 3)
func _get_slot_number(slot: Node) -> int:
	if not slot:
		return 0
	var slot_name = String(slot.name)  # Convert StringName to String
	# Extract number from slot name (e.g., "PlayerSlot3" -> 3)
	var number_str = ""
	for i in range(slot_name.length() - 1, -1, -1):
		if slot_name[i].is_valid_int():
			number_str = slot_name[i] + number_str
		else:
			break
	if number_str.is_valid_int():
		return number_str.to_int()
	return 0

# Helper to find slot by number
func _find_slot_by_number(slots: Array, slot_number: int) -> Node:
	for slot in slots:
		if _get_slot_number(slot) == slot_number:
			return slot
	return null

# Helper to get card from slot
func _get_card_from_slot(slot: Node) -> Node2D:
	if not slot:
		return null
	var current_card = null
	if "current_card" in slot:
		current_card = slot.current_card
	elif slot.has_method("get_current_card"):
		current_card = slot.get_current_card()
	return current_card

# Show a rising number that fades out
func _show_rising_number(position: Vector2, text: String, color: Color) -> void:
	var main_node = get_tree().current_scene
	if not main_node:
		return
	
	# Create label for the number
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.size = Vector2(100, 60)
	label.position = position
	label.z_index = 2000  # High z-index to appear on top
	
	# Add to scene
	main_node.add_child(label)
	
	# Animate rising and fading
	var tween = get_tree().create_tween()
	tween.set_parallel(true)  # Run animations in parallel
	tween.tween_property(label, "position", position + Vector2(0, -100), 1.0)
	tween.tween_property(label, "modulate", Color(color.r, color.g, color.b, 0), 1.0)
	
	# Wait for animation and remove
	await tween.finished
	label.queue_free()

# Apply healing from cards (kept for backwards compatibility, but not used in slot-by-slot resolution)
func apply_healing() -> void:
	if not game_state:
		return
	
	# Player healing
	var main_node = get_tree().current_scene
	var player_slots = []
	_find_player_slots(main_node, player_slots)
	
	var player_heal = 0
	for slot in player_slots:
		var current_card = _get_card_from_slot(slot)
		if current_card and is_instance_valid(current_card):
			var card_data = null
			if "card_data" in current_card:
				card_data = current_card.card_data
			
			if card_data and card_data.heal_value > 0:
				player_heal += card_data.heal_value
	
	if player_heal > 0 and game_state.has_method("heal_player"):
		game_state.heal_player(player_heal)
	
	# Enemy healing
	var enemy_slots = []
	_find_enemy_slots(main_node, enemy_slots)
	
	var enemy_heal = 0
	for slot in enemy_slots:
		var current_card = _get_card_from_slot(slot)
		if current_card and is_instance_valid(current_card):
			var card_data = null
			if "card_data" in current_card:
				card_data = current_card.card_data
			
			if card_data and card_data.heal_value > 0:
				enemy_heal += card_data.heal_value
	
	if enemy_heal > 0 and game_state.has_method("heal_enemy"):
		game_state.heal_enemy(enemy_heal)

# Recursively find all player slots
func _find_player_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("PlayerSlot"):
		result.append(node)
	
	for child in node.get_children():
		_find_player_slots(child, result)

# Recursively find all enemy slots
func _find_enemy_slots(node: Node, result: Array) -> void:
	if node.name.begins_with("EnemySlot"):
		result.append(node)
	
	for child in node.get_children():
		_find_enemy_slots(child, result)
