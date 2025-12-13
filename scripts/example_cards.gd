# This script creates example cards for testing
# Cards use the new ability slot system where:
# - Each card defines up to 5 ability slots
# - Rarity determines how many slots are active (Common=1, Uncommon=2, etc.)
# - Each slot's value is rolled based on the card's rarity

class_name ExampleCards

# ============================================
# SULFUR CARDS (Fire/Destruction)
# ============================================

static func create_flame_burst(card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var card = CardData.new()
	card.card_name = "Flame Burst"
	card.element = CardData.ElementType.SULFUR
	card.rarity = card_rarity
	
	# Define ability slots (up to 5) - only rarity-count are active
	card.add_ability("fire_damage")      # Slot 1 (Common+)
	card.add_ability("draw")             # Slot 2 (Uncommon+)
	card.add_ability("combo_damage")     # Slot 3 (Rare+)
	card.add_ability("burn_damage")      # Slot 4 (Epic+)
	card.add_ability("ignores_block")    # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

static func create_inferno(card_rarity: CardData.Rarity = CardData.Rarity.RARE) -> CardData:
	var card = CardData.new()
	card.card_name = "Inferno"
	card.element = CardData.ElementType.SULFUR
	card.rarity = card_rarity
	
	card.add_ability("fire_damage")      # Slot 1 (Common+)
	card.add_ability("combo_damage")     # Slot 2 (Uncommon+)
	card.add_ability("burn_damage")      # Slot 3 (Rare+)
	card.add_ability("fire_damage")      # Slot 4 (Epic+) - double fire damage!
	card.add_ability("ignores_block")    # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

static func create_sulfur_shard(card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var card = CardData.new()
	card.card_name = "Sulfur Shard"
	card.element = CardData.ElementType.SULFUR
	card.rarity = card_rarity
	
	card.add_ability("fire_damage")      # Slot 1 (Common+)
	card.add_ability("burn_damage")      # Slot 2 (Uncommon+)
	card.add_ability("combo_damage")     # Slot 3 (Rare+)
	card.add_ability("draw")             # Slot 4 (Epic+)
	card.add_ability("fire_damage")      # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

# ============================================
# MERCURY CARDS (Liquid/Transformation)
# ============================================

static func create_quicksilver(card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var card = CardData.new()
	card.card_name = "Quicksilver"
	card.element = CardData.ElementType.MERCURY
	card.rarity = card_rarity
	
	card.add_ability("draw")             # Slot 1 (Common+)
	card.add_ability("fire_damage")      # Slot 2 (Uncommon+)
	card.add_ability("draw")             # Slot 3 (Rare+) - extra draw
	card.add_ability("combo_damage")     # Slot 4 (Epic+)
	card.add_ability("ignores_block")    # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

static func create_flux(card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var card = CardData.new()
	card.card_name = "Flux"
	card.element = CardData.ElementType.MERCURY
	card.rarity = card_rarity
	
	card.add_ability("draw")             # Slot 1 (Common+)
	card.add_ability("draw")             # Slot 2 (Uncommon+) - double draw
	card.add_ability("heal")             # Slot 3 (Rare+)
	card.add_ability("block")            # Slot 4 (Epic+)
	card.add_ability("draw")             # Slot 5 (Legendary) - triple draw!
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

# ============================================
# SALT CARDS (Earth/Stability)
# ============================================

static func create_stone_wall(card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var card = CardData.new()
	card.card_name = "Stone Wall"
	card.element = CardData.ElementType.SALT
	card.rarity = card_rarity
	
	card.add_ability("block")            # Slot 1 (Common+)
	card.add_ability("block")            # Slot 2 (Uncommon+) - double block
	card.add_ability("heal")             # Slot 3 (Rare+)
	card.add_ability("block")            # Slot 4 (Epic+) - triple block!
	card.add_ability("draw")             # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

static func create_granite_shield(card_rarity: CardData.Rarity = CardData.Rarity.RARE) -> CardData:
	var card = CardData.new()
	card.card_name = "Granite Shield"
	card.element = CardData.ElementType.SALT
	card.rarity = card_rarity
	
	card.add_ability("block")            # Slot 1 (Common+)
	card.add_ability("heal")             # Slot 2 (Uncommon+)
	card.add_ability("block")            # Slot 3 (Rare+)
	card.add_ability("fire_damage")      # Slot 4 (Epic+) - counter attack!
	card.add_ability("block")            # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

static func create_salt_barrier(card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var card = CardData.new()
	card.card_name = "Salt Barrier"
	card.element = CardData.ElementType.SALT
	card.rarity = card_rarity
	
	card.add_ability("block")            # Slot 1 (Common+)
	card.add_ability("draw")             # Slot 2 (Uncommon+)
	card.add_ability("block")            # Slot 3 (Rare+)
	card.add_ability("heal")             # Slot 4 (Epic+)
	card.add_ability("block")            # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

# ============================================
# VITAE CARDS (Life/Growth)
# ============================================

static func create_life_bloom(card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var card = CardData.new()
	card.card_name = "Life Bloom"
	card.element = CardData.ElementType.VITAE
	card.rarity = card_rarity
	
	card.add_ability("heal")             # Slot 1 (Common+)
	card.add_ability("heal")             # Slot 2 (Uncommon+) - double heal
	card.add_ability("draw")             # Slot 3 (Rare+)
	card.add_ability("heal")             # Slot 4 (Epic+) - triple heal!
	card.add_ability("block")            # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

static func create_vital_surge(card_rarity: CardData.Rarity = CardData.Rarity.RARE) -> CardData:
	var card = CardData.new()
	card.card_name = "Vital Surge"
	card.element = CardData.ElementType.VITAE
	card.rarity = card_rarity
	
	card.add_ability("heal")             # Slot 1 (Common+)
	card.add_ability("block")            # Slot 2 (Uncommon+)
	card.add_ability("heal")             # Slot 3 (Rare+)
	card.add_ability("draw")             # Slot 4 (Epic+)
	card.add_ability("heal")             # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

static func create_regeneration(card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var card = CardData.new()
	card.card_name = "Regeneration"
	card.element = CardData.ElementType.VITAE
	card.rarity = card_rarity
	
	card.add_ability("heal")             # Slot 1 (Common+)
	card.add_ability("draw")             # Slot 2 (Uncommon+)
	card.add_ability("heal")             # Slot 3 (Rare+)
	card.add_ability("block")            # Slot 4 (Epic+)
	card.add_ability("heal")             # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

# ============================================
# AETHER CARDS (Spirit/Energy)
# ============================================

static func create_aether_bolt(card_rarity: CardData.Rarity = CardData.Rarity.RARE) -> CardData:
	var card = CardData.new()
	card.card_name = "Aether Bolt"
	card.element = CardData.ElementType.AETHER
	card.rarity = card_rarity
	
	card.add_ability("fire_damage")      # Slot 1 (Common+)
	card.add_ability("ignores_block")    # Slot 2 (Uncommon+) - piercing!
	card.add_ability("combo_damage")     # Slot 3 (Rare+)
	card.add_ability("fire_damage")      # Slot 4 (Epic+)
	card.add_ability("draw")             # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

static func create_spirit_echo(card_rarity: CardData.Rarity = CardData.Rarity.EPIC) -> CardData:
	var card = CardData.new()
	card.card_name = "Spirit Echo"
	card.element = CardData.ElementType.AETHER
	card.rarity = card_rarity
	# Special card - copies effects, minimal base abilities
	
	card.add_ability("draw")             # Slot 1 (Common+)
	card.add_ability("fire_damage")      # Slot 2 (Uncommon+)
	card.add_ability("heal")             # Slot 3 (Rare+)
	card.add_ability("block")            # Slot 4 (Epic+)
	card.add_ability("ignores_block")    # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

static func create_void_shift(card_rarity: CardData.Rarity = CardData.Rarity.RARE) -> CardData:
	var card = CardData.new()
	card.card_name = "Void Shift"
	card.element = CardData.ElementType.AETHER
	card.rarity = card_rarity
	# Utility card with mixed abilities
	
	card.add_ability("draw")             # Slot 1 (Common+)
	card.add_ability("block")            # Slot 2 (Uncommon+)
	card.add_ability("fire_damage")      # Slot 3 (Rare+)
	card.add_ability("heal")             # Slot 4 (Epic+)
	card.add_ability("ignores_block")    # Slot 5 (Legendary)
	
	card.roll_stats()
	card.description = card.generate_description()
	return card

# ============================================
# DECK CREATION
# ============================================

static func create_starter_enemy_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# 20 Common Flame Burst cards for enemy
	for i in 20:
		deck.append(create_flame_burst(CardData.Rarity.COMMON))
	return deck

# Create a starter deck (30 cards) - all Common rarity for starter
static func create_starter_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# 6 Sulfur cards
	for i in 3:
		deck.append(create_flame_burst(CardData.Rarity.COMMON))
	for i in 2:
		deck.append(create_sulfur_shard(CardData.Rarity.COMMON))
	deck.append(create_inferno(CardData.Rarity.RARE))  # One rare card
	
	# 6 Mercury cards
	for i in 4:
		deck.append(create_quicksilver(CardData.Rarity.COMMON))
	for i in 2:
		deck.append(create_flux(CardData.Rarity.COMMON))
	
	# 8 Salt cards
	for i in 4:
		deck.append(create_stone_wall(CardData.Rarity.COMMON))
	for i in 2:
		deck.append(create_salt_barrier(CardData.Rarity.COMMON))
	for i in 2:
		deck.append(create_granite_shield(CardData.Rarity.RARE))  # Rare cards
	
	# 6 Vitae cards
	for i in 3:
		deck.append(create_life_bloom(CardData.Rarity.COMMON))
	for i in 2:
		deck.append(create_regeneration(CardData.Rarity.COMMON))
	deck.append(create_vital_surge(CardData.Rarity.RARE))  # One rare card
	
	# 4 Aether cards
	for i in 2:
		deck.append(create_aether_bolt(CardData.Rarity.RARE))  # Rare cards
	deck.append(create_spirit_echo(CardData.Rarity.EPIC))  # One epic card
	deck.append(create_void_shift(CardData.Rarity.RARE))
	
	return deck
