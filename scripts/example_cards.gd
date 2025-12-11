# This script creates example cards for testing
# You can use these as templates to create .tres resource files in Godot editor

class_name ExampleCards

# Helper function to create card data
static func create_flame_burst() -> CardData:
	var card = CardData.new()
	card.card_name = "Flame Burst"
	card.description = "Deal 8 damage to facing enemy"
	card.element = CardData.ElementType.SULFUR
	card.rarity = CardData.Rarity.COMMON
	card.damage_range = Vector2i(7, 9)  # Random 7-9 damage
	card.roll_stats()
	return card

static func create_inferno() -> CardData:
	var card = CardData.new()
	card.card_name = "Inferno"
	card.description = "Deal 12 damage. +3 if in combo"
	card.element = CardData.ElementType.SULFUR
	card.rarity = CardData.Rarity.RARE
	card.damage_range = Vector2i(10, 14)
	card.combo_damage_bonus = 3
	card.roll_stats()
	return card

static func create_sulfur_shard() -> CardData:
	var card = CardData.new()
	card.card_name = "Sulfur Shard"
	card.description = "Deal 5 damage. +3 if adjacent slot empty"
	card.element = CardData.ElementType.SULFUR
	card.rarity = CardData.Rarity.COMMON
	card.damage_range = Vector2i(4, 6)
	card.bonus_if_adjacent_empty = true
	card.roll_stats()
	return card

static func create_quicksilver() -> CardData:
	var card = CardData.new()
	card.card_name = "Quicksilver"
	card.description = "Draw 1 card, deal 4 damage"
	card.element = CardData.ElementType.MERCURY
	card.rarity = CardData.Rarity.COMMON
	card.damage_range = Vector2i(3, 5)
	card.draw_amount = 1
	card.roll_stats()
	return card

static func create_flux() -> CardData:
	var card = CardData.new()
	card.card_name = "Flux"
	card.description = "Draw 2 cards"
	card.element = CardData.ElementType.MERCURY
	card.rarity = CardData.Rarity.COMMON
	card.draw_amount = 2
	card.roll_stats()
	return card

static func create_stone_wall() -> CardData:
	var card = CardData.new()
	card.card_name = "Stone Wall"
	card.description = "Gain 8 block"
	card.element = CardData.ElementType.SALT
	card.rarity = CardData.Rarity.COMMON
	card.block_range = Vector2i(7, 9)
	card.roll_stats()
	return card

static func create_granite_shield() -> CardData:
	var card = CardData.new()
	card.card_name = "Granite Shield"
	card.description = "Gain 12 block. +4 if in combo"
	card.element = CardData.ElementType.SALT
	card.rarity = CardData.Rarity.RARE
	card.block_range = Vector2i(10, 14)
	card.combo_block_bonus = 4
	card.roll_stats()
	return card

static func create_salt_barrier() -> CardData:
	var card = CardData.new()
	card.card_name = "Salt Barrier"
	card.description = "Gain 6 block. Stacks with adjacent Salt"
	card.element = CardData.ElementType.SALT
	card.rarity = CardData.Rarity.COMMON
	card.block_range = Vector2i(5, 7)
	card.roll_stats()
	return card

static func create_life_bloom() -> CardData:
	var card = CardData.new()
	card.card_name = "Life Bloom"
	card.description = "Heal 6 HP"
	card.element = CardData.ElementType.VITAE
	card.rarity = CardData.Rarity.COMMON
	card.heal_range = Vector2i(5, 7)
	card.roll_stats()
	return card

static func create_vital_surge() -> CardData:
	var card = CardData.new()
	card.card_name = "Vital Surge"
	card.description = "Heal 10 HP if facing empty slot"
	card.element = CardData.ElementType.VITAE
	card.rarity = CardData.Rarity.RARE
	card.heal_range = Vector2i(8, 12)
	card.bonus_if_facing_empty = true
	card.roll_stats()
	return card

static func create_regeneration() -> CardData:
	var card = CardData.new()
	card.card_name = "Regeneration"
	card.description = "Heal 4 HP. +2 per Vitae in combo"
	card.element = CardData.ElementType.VITAE
	card.rarity = CardData.Rarity.COMMON
	card.heal_range = Vector2i(3, 5)
	card.combo_heal_bonus = 2
	card.roll_stats()
	return card

static func create_aether_bolt() -> CardData:
	var card = CardData.new()
	card.card_name = "Aether Bolt"
	card.description = "Deal 6 damage. Ignores block"
	card.element = CardData.ElementType.AETHER
	card.rarity = CardData.Rarity.RARE
	card.damage_range = Vector2i(5, 7)
	card.ignores_block = true
	card.roll_stats()
	return card

static func create_spirit_echo() -> CardData:
	var card = CardData.new()
	card.card_name = "Spirit Echo"
	card.description = "Repeat your leftmost card's effect"
	card.element = CardData.ElementType.AETHER
	card.rarity = CardData.Rarity.EPIC
	# This will need special handling in resolution
	card.roll_stats()
	return card

static func create_void_shift() -> CardData:
	var card = CardData.new()
	card.card_name = "Void Shift"
	card.description = "Swap positions of two cards (before reveal)"
	card.element = CardData.ElementType.AETHER
	card.rarity = CardData.Rarity.RARE
	# This will need special handling in placement phase
	card.roll_stats()
	return card

static func create_starter_enemy_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# 20 Flame Burst cards
	for i in 20:
		deck.append(create_flame_burst())
	return deck

# Create a starter deck (30 cards)
static func create_starter_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# 6 Sulfur cards
	for i in 3:
		deck.append(create_flame_burst())
	for i in 2:
		deck.append(create_sulfur_shard())
	deck.append(create_inferno())
	
	# 6 Mercury cards
	for i in 4:
		deck.append(create_quicksilver())
	for i in 2:
		deck.append(create_flux())
	
	# 8 Salt cards
	for i in 4:
		deck.append(create_stone_wall())
	for i in 2:
		deck.append(create_salt_barrier())
	for i in 2:
		deck.append(create_granite_shield())
	
	# 6 Vitae cards
	for i in 3:
		deck.append(create_life_bloom())
	for i in 2:
		deck.append(create_regeneration())
	deck.append(create_vital_surge())
	
	# 4 Aether cards
	for i in 2:
		deck.append(create_aether_bolt())
	deck.append(create_spirit_echo())
	deck.append(create_void_shift())
	
	return deck
