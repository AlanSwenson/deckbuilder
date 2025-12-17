extends Node
class_name DamageCalculator

# References (set by TurnLogic)
var game_state: Node2D = null
var turn_history: Control = null
var player_hand: Node2D = null
var player_deck: Node2D = null
var enemy_hand: Node2D = null
var enemy_deck: Node2D = null
var card_manager: Node2D = null

const CARD_SCENE_PATH = "res://scenes/Card.tscn"

func setup(game_state_ref: Node2D, turn_history_ref: Control = null, player_hand_ref: Node2D = null, player_deck_ref: Node2D = null, enemy_hand_ref: Node2D = null, enemy_deck_ref: Node2D = null, card_manager_ref: Node2D = null) -> void:
	game_state = game_state_ref
	turn_history = turn_history_ref
	player_hand = player_hand_ref
	player_deck = player_deck_ref
	enemy_hand = enemy_hand_ref
	enemy_deck = enemy_deck_ref
	card_manager = card_manager_ref

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
				var damage = card_data.get_total_damage()
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
				var damage = card_data.get_total_damage()
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
	
	print("[DamageCalculator] Found ", player_slots.size(), " player slots and ", enemy_slots.size(), " enemy slots")
	for slot in player_slots:
		var slot_num = _get_slot_number(slot)
		var card = _get_card_from_slot(slot)
		var card_name = "Empty"
		if card and is_instance_valid(card) and "card_data" in card:
			card_name = card.card_data.card_name if card.card_data else "No data"
		print("[DamageCalculator] Player slot: ", slot.name, " (number: ", slot_num, ") has card: ", card_name)
	
	for slot in enemy_slots:
		var slot_num = _get_slot_number(slot)
		var card = _get_card_from_slot(slot)
		var card_name = "Empty"
		if card and is_instance_valid(card) and "card_data" in card:
			card_name = card.card_data.card_name if card.card_data else "No data"
		print("[DamageCalculator] Enemy slot: ", slot.name, " (number: ", slot_num, ") has card: ", card_name)
	
	print("[DamageCalculator] Resolving turn slot by slot...")
	
	# Store card references and data for all slots to use during resolution
	# This prevents issues if cards are removed from slots between logging and resolution
	var slot_cards: Dictionary = {}  # slot_index -> {player_card, player_card_data, enemy_card, enemy_card_data}
	
	# First, log ALL cards in ALL slots before resolving (so we see what was played)
	if turn_history and turn_history.has_method("add_slot_cards"):
		for slot_index in range(1, 6):  # Slots 1-5
			var player_slot = _find_slot_by_number(player_slots, slot_index)
			var enemy_slot = _find_slot_by_number(enemy_slots, slot_index)
			
			# Get cards from slots
			var player_card = null
			var player_card_data = null
			var enemy_card = null
			var enemy_card_data = null
			
			if player_slot:
				player_card = _get_card_from_slot(player_slot)
				print("[DamageCalculator] LOGGING Slot ", slot_index, ": Retrieved player_card: ", player_card.name if player_card and is_instance_valid(player_card) else "null/invalid")
				if player_card and is_instance_valid(player_card) and "card_data" in player_card:
					player_card_data = player_card.card_data
					print("[DamageCalculator] LOGGING Slot ", slot_index, ": Found player_card_data: ", player_card_data.card_name if player_card_data else "null")
				else:
					print("[DamageCalculator] LOGGING Slot ", slot_index, ": player_card missing or has no card_data")
			else:
				print("[DamageCalculator] LOGGING Slot ", slot_index, ": player_slot is null")
			
			if enemy_slot:
				enemy_card = _get_card_from_slot(enemy_slot)
				if enemy_card and is_instance_valid(enemy_card) and "card_data" in enemy_card:
					enemy_card_data = enemy_card.card_data
			
			# Build effect descriptions using new ability system
			var player_description = ""
			var enemy_description = ""
			
			if player_card_data:
				var effects = []
				var damage = player_card_data.get_total_damage()
				if damage > 0:
					effects.append(str(damage) + " DMG")
				
				var heal = player_card_data.get_total_heal()
				if heal > 0:
					effects.append("+" + str(heal) + " Heal")
				
				var block = player_card_data.get_total_block()
				if block > 0:
					effects.append(str(block) + " Block")
				
				var draw = player_card_data.get_total_draw()
				if draw > 0:
					effects.append("Draw " + str(draw))
				
				if player_card_data.ignores_block():
					effects.append("Piercing")
				
				if effects.size() > 0:
					player_description = player_card_data.card_name + " (" + ", ".join(effects) + ")"
				else:
					player_description = player_card_data.card_name + " (no effects)"
			
			if enemy_card_data:
				var effects = []
				var damage = enemy_card_data.get_total_damage()
				if damage > 0:
					effects.append(str(damage) + " DMG")
				
				var heal = enemy_card_data.get_total_heal()
				if heal > 0:
					effects.append("+" + str(heal) + " Heal")
				
				var block = enemy_card_data.get_total_block()
				if block > 0:
					effects.append(str(block) + " Block")
				
				var draw = enemy_card_data.get_total_draw()
				if draw > 0:
					effects.append("Draw " + str(draw))
				
				if enemy_card_data.ignores_block():
					effects.append("Piercing")
				
				if effects.size() > 0:
					enemy_description = enemy_card_data.card_name + " (" + ", ".join(effects) + ")"
				else:
					enemy_description = enemy_card_data.card_name + " (no effects)"
			
			# Log this slot's cards
			turn_history.add_slot_cards(slot_index, player_description, enemy_description)
			
			# Store card references and slot references for resolution phase
			slot_cards[slot_index] = {
				"player_card": player_card,
				"player_card_data": player_card_data,
				"enemy_card": enemy_card,
				"enemy_card_data": enemy_card_data,
				"player_slot": player_slot,
				"enemy_slot": enemy_slot
			}
	
	# Now resolve each slot (1-5)
	for slot_index in range(1, 6):  # Slots 1-5
		# Check if game ended (but continue processing slots for visual consistency)
		if game_state and game_state.has_method("is_game_playing"):
			if not game_state.is_game_playing():
				print("[DamageCalculator] Game ended, but continuing slot resolution for visual consistency at slot ", slot_index)
				# Don't return - continue processing slots even if game ended
		
		print("[DamageCalculator] ===== Resolving Slot ", slot_index, " =====")
		
		# Use stored card references from logging phase (more reliable than re-fetching)
		var player_card = null
		var player_card_data = null
		var enemy_card = null
		var enemy_card_data = null
		var player_slot = null
		var enemy_slot = null
		
		if slot_index in slot_cards:
			var stored = slot_cards[slot_index]
			player_card = stored.get("player_card")
			player_card_data = stored.get("player_card_data")
			enemy_card = stored.get("enemy_card")
			enemy_card_data = stored.get("enemy_card_data")
			player_slot = stored.get("player_slot")
			enemy_slot = stored.get("enemy_slot")
			print("[DamageCalculator] Slot ", slot_index, ": Using stored card references - player_card: ", player_card.name if player_card and is_instance_valid(player_card) else "null", ", enemy_card: ", enemy_card.name if enemy_card and is_instance_valid(enemy_card) else "null")
		else:
			print("[DamageCalculator] Slot ", slot_index, ": WARNING - No stored card data found, trying to fetch from slots")
			# Fallback: try to get from slots directly
			player_slot = _find_slot_by_number(player_slots, slot_index)
			enemy_slot = _find_slot_by_number(enemy_slots, slot_index)
			
			if player_slot:
				player_card = _get_card_from_slot(player_slot)
				if player_card and is_instance_valid(player_card) and "card_data" in player_card:
					player_card_data = player_card.card_data
			
			if enemy_slot:
				enemy_card = _get_card_from_slot(enemy_slot)
				if enemy_card and is_instance_valid(enemy_card) and "card_data" in enemy_card:
					enemy_card_data = enemy_card.card_data
		
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
		
		# Resolve player card effects using new ability system
		var player_damage = 0
		var player_heal = 0
		var player_block = 0
		var player_draw = 0
		var player_max_hand_size_increase = 0
		var player_ignores_block = false
		if player_card_data:
			player_damage = player_card_data.get_total_damage()
			player_heal = player_card_data.get_total_heal()
			player_block = player_card_data.get_total_block()
			player_draw = player_card_data.get_total_draw()
			player_max_hand_size_increase = player_card_data.get_total_max_hand_size_increase()
			player_ignores_block = player_card_data.ignores_block()
			
			print("[DamageCalculator] Slot ", slot_index, ": Resolving player card - name: ", player_card_data.card_name)
			if player_damage > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Player card ", player_card_data.card_name, " deals ", player_damage, " damage")
			if player_heal > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Player card ", player_card_data.card_name, " heals ", player_heal)
			if player_block > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Player card ", player_card_data.card_name, " blocks ", player_block)
			if player_ignores_block:
				print("[DamageCalculator] Slot ", slot_index, ": Player card ", player_card_data.card_name, " ignores block")
		else:
			print("[DamageCalculator] Slot ", slot_index, ": No player card data found")
		
		# Resolve enemy card effects using new ability system
		var enemy_damage = 0
		var enemy_heal = 0
		var enemy_block = 0
		var enemy_draw = 0
		var enemy_max_hand_size_increase = 0
		var enemy_ignores_block = false
		if enemy_card_data:
			enemy_damage = enemy_card_data.get_total_damage()
			enemy_heal = enemy_card_data.get_total_heal()
			enemy_block = enemy_card_data.get_total_block()
			enemy_draw = enemy_card_data.get_total_draw()
			enemy_max_hand_size_increase = enemy_card_data.get_total_max_hand_size_increase()
			enemy_ignores_block = enemy_card_data.ignores_block()
			
			if enemy_damage > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Enemy card ", enemy_card_data.card_name, " deals ", enemy_damage, " damage")
			if enemy_heal > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Enemy card ", enemy_card_data.card_name, " heals ", enemy_heal)
			if enemy_block > 0:
				print("[DamageCalculator] Slot ", slot_index, ": Enemy card ", enemy_card_data.card_name, " blocks ", enemy_block)
			if enemy_ignores_block:
				print("[DamageCalculator] Slot ", slot_index, ": Enemy card ", enemy_card_data.card_name, " ignores block")
		
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
			# Check if player card ignores block
			if not player_ignores_block:
				final_player_damage = max(0, player_damage - enemy_block)
				if enemy_block > 0 and final_player_damage < player_damage:
					print("[DamageCalculator] Slot ", slot_index, ": Enemy block reduced damage from ", player_damage, " to ", final_player_damage)
			
			print("[DamageCalculator] Slot ", slot_index, ": Player damage calculation - base: ", player_damage, ", enemy_block: ", enemy_block, ", final: ", final_player_damage)
			
			if final_player_damage > 0:
				if game_state:
					print("[DamageCalculator] Calling damage_enemy(", final_player_damage, ") on game_state: ", game_state.name)
					game_state.damage_enemy(final_player_damage)
					# Queue damage number to show
					var offset_pos = display_position + Vector2(effect_count * 60 - 30, 0)
					numbers_to_show.append({"position": offset_pos, "text": "-" + str(final_player_damage), "color": Color.RED})
					effect_count += 1
				else:
					print("[DamageCalculator] ERROR: game_state is null, cannot apply damage")
			else:
				print("[DamageCalculator] Slot ", slot_index, ": Final player damage is 0, not applying")
		
		# Enemy damage to player
		if enemy_damage > 0:
			var final_enemy_damage = enemy_damage
			# Check if enemy card ignores block
			if not enemy_ignores_block:
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
		
		# Apply max hand size increase effects FIRST (update display immediately)
		if player_max_hand_size_increase > 0:
			print("[DamageCalculator] Slot ", slot_index, ": Player card increases player max hand size by ", player_max_hand_size_increase)
			if game_state:
				game_state.player_max_hand_size += player_max_hand_size_increase
				print("[DamageCalculator] Player max hand size is now ", game_state.player_max_hand_size)
				# Update display immediately when ability is processed
				game_state.update_hand_size_display()
				# Small delay to ensure UI update is visible
				await get_tree().process_frame
		
		if enemy_max_hand_size_increase > 0:
			print("[DamageCalculator] Slot ", slot_index, ": Enemy card increases enemy max hand size by ", enemy_max_hand_size_increase)
			if game_state:
				game_state.enemy_max_hand_size += enemy_max_hand_size_increase
				print("[DamageCalculator] Enemy max hand size is now ", game_state.enemy_max_hand_size)
				# Update display immediately when ability is processed
				game_state.update_hand_size_display()
				# Small delay to ensure UI update is visible
				await get_tree().process_frame
		
		# Apply draw effects - draw cards to hand
		if player_draw > 0:
			print("[DamageCalculator] Slot ", slot_index, ": Player card draws ", player_draw, " card(s)")
			await _draw_cards_to_hand(player_draw, false)  # false = player
		
		if enemy_draw > 0:
			print("[DamageCalculator] Slot ", slot_index, ": Enemy card draws ", enemy_draw, " card(s)")
			await _draw_cards_to_hand(enemy_draw, true)  # true = enemy
		
		# Show all numbers at once (non-blocking)
		for number_data in numbers_to_show:
			_show_rising_number(number_data.position, number_data.text, number_data.color)
		
		# Log if no effects occurred (cards were played but had no effects)
		if numbers_to_show.is_empty():
			if turn_history and turn_history.has_method("add_line"):
				if player_card_data or enemy_card_data:
					# Cards were played but had no effects
					turn_history.add_line("  → No effects", Color.GRAY)
				# If no cards at all, we already logged that in add_slot_cards
			print("[DamageCalculator] Slot ", slot_index, " resolved: No effects")
		else:
			print("[DamageCalculator] Slot ", slot_index, " resolved: ", numbers_to_show.size(), " effect(s)")
		
		# Lower player card back to original position
		if player_card and is_instance_valid(player_card) and player_card_original_position != null:
			var lower_tween = get_tree().create_tween()
			lower_tween.tween_property(player_card, "global_position", player_card_original_position, 0.2)
			await lower_tween.finished
			# Remove flag after animation completes
			if player_card and is_instance_valid(player_card) and player_card.has_meta("evaluating_slot"):
				player_card.remove_meta("evaluating_slot")
		
		# Always wait a moment between slots for visual feedback, even if empty
		# This ensures all slots are processed with consistent timing
		await get_tree().create_timer(0.3).timeout
		
		# HP/block displays are updated automatically by GameState methods
		# Add a small delay for visual feedback
		await get_tree().create_timer(0.2).timeout
		
		# Note: We continue processing all slots even if game ended for visual consistency
		# The GameState.damage_enemy() and damage_player() methods will check game status internally

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
	# Try both methods to get the card
	if "current_card" in slot:
		current_card = slot.current_card
		if current_card:
			print("[DamageCalculator] _get_card_from_slot: Found card via slot.current_card: ", current_card.name if is_instance_valid(current_card) else "invalid")
	
	if not current_card and slot.has_method("get_current_card"):
		current_card = slot.get_current_card()
		if current_card:
			print("[DamageCalculator] _get_card_from_slot: Found card via get_current_card(): ", current_card.name if is_instance_valid(current_card) else "invalid")
	
	if not current_card:
		print("[DamageCalculator] _get_card_from_slot: No card found in slot ", slot.name, " (has current_card property: ", "current_card" in slot, ", has get_current_card method: ", slot.has_method("get_current_card"), ")")
	
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
			
			if card_data:
				player_heal += card_data.get_total_heal()
	
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
			
			if card_data:
				enemy_heal += card_data.get_total_heal()
	
	if enemy_heal > 0 and game_state.has_method("heal_enemy"):
		game_state.heal_enemy(enemy_heal)

# Draw cards to hand when draw ability is triggered
func _draw_cards_to_hand(count: int, is_enemy: bool) -> void:
	if count <= 0:
		return
	
	var hand = enemy_hand if is_enemy else player_hand
	var deck = enemy_deck if is_enemy else player_deck
	var hand_y = 110.0 if is_enemy else 890.0
	var card_name_prefix = "EnemyCard" if is_enemy else "Card"
	var deck_slot_name = "DeckSlotEnemy" if is_enemy else "DeckSlotPlayer"
	
	if not hand or not deck or not card_manager:
		print("[DamageCalculator] Cannot draw cards - missing references (hand: %s, deck: %s, card_manager: %s)" % [str(hand != null), str(deck != null), str(card_manager != null)])
		return
	
	# Get current hand size for positioning
	var current_hand_size = 0
	if is_enemy and "enemy_hand" in hand:
		current_hand_size = hand.enemy_hand.size()
	elif not is_enemy and "player_hand" in hand:
		current_hand_size = hand.player_hand.size()
	
	print("[DamageCalculator] Drawing %d card(s) to %s hand (current size: %d)" % [count, "enemy" if is_enemy else "player", current_hand_size])
	
	# Use HandRefiller's method if available, otherwise create our own
	var hand_refiller = get_tree().current_scene.get_node_or_null("TurnLogic/HandRefiller")
	if hand_refiller and hand_refiller.has_method("_create_and_animate_card_to_hand"):
		# Use existing HandRefiller method
		for i in range(count):
			# Check if game is still playing
			if game_state and game_state.has_method("is_game_playing"):
				if not game_state.is_game_playing():
					print("[DamageCalculator] Game ended, stopping card draw")
					break
			
			var card_data = deck.draw_card() if deck.has_method("draw_card") else null
			if not card_data:
				print("[DamageCalculator] WARNING: Could not draw card %d - deck may be empty" % (i + 1))
				break
			
			await hand_refiller._create_and_animate_card_to_hand(card_data, hand, deck, card_name_prefix, deck_slot_name, hand_y, current_hand_size + i, is_enemy)
			
			# Small delay between cards
			if i < count - 1:
				await get_tree().create_timer(0.05).timeout
	else:
		# Fallback: create cards directly
		var card_scene = load(CARD_SCENE_PATH)
		for i in range(count):
			# Check if game is still playing
			if game_state and game_state.has_method("is_game_playing"):
				if not game_state.is_game_playing():
					print("[DamageCalculator] Game ended, stopping card draw")
					break
			
			var card_data = deck.draw_card() if deck.has_method("draw_card") else null
			if not card_data:
				print("[DamageCalculator] WARNING: Could not draw card %d - deck may be empty" % (i + 1))
				break
			
			# Create card instance
			var new_card = card_scene.instantiate()
			if not new_card:
				print("[DamageCalculator] ERROR: Failed to instantiate card scene")
				continue
			
			# Get card number from hand
			var card_number = 1
			if "card_id_counter" in hand:
				card_number = hand.card_id_counter
				hand.card_id_counter += 1
			
			new_card.name = card_name_prefix + str(card_number)
			
			# Set card number
			if new_card.has_method("set_card_number"):
				new_card.set_card_number(card_number)
			new_card.set_meta("card_number", card_number)
			if is_enemy:
				new_card.set_meta("is_enemy_card", true)
			
			# Position card at deck location
			var main_node = get_tree().current_scene
			var deck_slot = main_node.get_node_or_null(deck_slot_name)
			if deck_slot:
				var deck_local_position = card_manager.to_local(deck_slot.global_position)
				new_card.position = deck_local_position
			
			# Add card to CardManager
			card_manager.add_child(new_card)
			await get_tree().process_frame
			
			# Set card data
			if new_card.has_method("set_card_data"):
				new_card.set_card_data(card_data)
			
			# Calculate target position in hand
			var target_x = 0.0
			if hand.has_method("calculate_card_position"):
				target_x = hand.calculate_card_position(current_hand_size + i)
			else:
				var card_width = 100
				var center_x = hand.center_screen_x if "center_screen_x" in hand else get_viewport().size.x / 2.0
				var total_width = (current_hand_size + i) * card_width
				target_x = center_x + (current_hand_size + i) * card_width - total_width / 2.0
			
			var target_position = Vector2(target_x, hand_y)
			
			# Play flip animation and animate to hand position
			var animation_player = new_card.get_node_or_null("AnimationPlayer")
			if animation_player and animation_player.has_animation("card_flip"):
				animation_player.play("card_flip")
			
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(new_card, "position", target_position, 0.2)
			await tween.finished
			
			# Add to hand array
			if is_enemy and "enemy_hand" in hand:
				hand.enemy_hand.append(new_card)
			elif not is_enemy and "player_hand" in hand:
				hand.player_hand.append(new_card)
			
			# Update hand positions
			if hand.has_method("update_hand_positions"):
				hand.update_hand_positions()
			
			# Register card with CardManager
			if card_manager and card_manager.has_method("register_card"):
				card_manager.register_card(new_card)
			
			# Small delay between cards
			if i < count - 1:
				await get_tree().create_timer(0.05).timeout

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
