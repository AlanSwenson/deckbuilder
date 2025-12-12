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

# Apply healing from cards
func apply_healing() -> void:
	if not game_state:
		return
	
	# Player healing
	var main_node = get_tree().current_scene
	var player_slots = []
	_find_player_slots(main_node, player_slots)
	
	var player_heal = 0
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
			
			if card_data and card_data.heal_value > 0:
				player_heal += card_data.heal_value
	
	if player_heal > 0 and game_state.has_method("heal_player"):
		game_state.heal_player(player_heal)
	
	# Enemy healing
	var enemy_slots = []
	_find_enemy_slots(main_node, enemy_slots)
	
	var enemy_heal = 0
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

