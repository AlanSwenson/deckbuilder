# Deck factory - creates starter decks using CardRegistry
# Individual cards can be created directly via CardRegistry.create_card()

class_name ExampleCards

# ============================================
# DECK CREATION
# ============================================

# Create starter enemy deck (20 Flame Burst cards)
static func create_starter_enemy_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# 20 Common Flame Burst cards for enemy
	for i in 20:
		var card = CardRegistry.create_card("Flame Burst", CardData.Rarity.COMMON)
		if card:
			deck.append(card)
	return deck

# Create a starter deck (30 cards) - mixed rarities for starter
static func create_starter_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# 6 Sulfur cards
	for i in 3:
		var card = CardRegistry.create_card("Flame Burst", CardData.Rarity.COMMON)
		if card:
			deck.append(card)
	for i in 2:
		var card = CardRegistry.create_card("Sulfur Shard", CardData.Rarity.COMMON)
		if card:
			deck.append(card)
	var inferno = CardRegistry.create_card("Inferno", CardData.Rarity.RARE)
	if inferno:
		deck.append(inferno)
	
	# 6 Mercury cards
	for i in 4:
		var card = CardRegistry.create_card("Quicksilver", CardData.Rarity.COMMON)
		if card:
			deck.append(card)
	for i in 2:
		var card = CardRegistry.create_card("Flux", CardData.Rarity.COMMON)
		if card:
			deck.append(card)
	
	# 8 Salt cards
	for i in 4:
		var card = CardRegistry.create_card("Stone Wall", CardData.Rarity.COMMON)
		if card:
			deck.append(card)
	for i in 2:
		var card = CardRegistry.create_card("Salt Barrier", CardData.Rarity.COMMON)
		if card:
			deck.append(card)
	for i in 2:
		var card = CardRegistry.create_card("Granite Shield", CardData.Rarity.RARE)
		if card:
			deck.append(card)
	
	# 6 Vitae cards
	for i in 3:
		var card = CardRegistry.create_card("Life Bloom", CardData.Rarity.COMMON)
		if card:
			deck.append(card)
	for i in 2:
		var card = CardRegistry.create_card("Regeneration", CardData.Rarity.COMMON)
		if card:
			deck.append(card)
	var vital = CardRegistry.create_card("Vital Surge", CardData.Rarity.RARE)
	if vital:
		deck.append(vital)
	
	# 4 Aether cards
	for i in 2:
		var card = CardRegistry.create_card("Aether Bolt", CardData.Rarity.RARE)
		if card:
			deck.append(card)
	var spirit = CardRegistry.create_card("Spirit Echo", CardData.Rarity.EPIC)
	if spirit:
		deck.append(spirit)
	var void_card = CardRegistry.create_card("Void Shift", CardData.Rarity.RARE)
	if void_card:
		deck.append(void_card)
	
	return deck

# ============================================
# UTILITY METHODS
# ============================================

# Create a random card of a specific element
static func create_random_card_by_element(element: CardData.ElementType, card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var cards_of_element = CardRegistry.get_cards_by_element(element)
	if cards_of_element.is_empty():
		return null
	
	var template = cards_of_element[randi() % cards_of_element.size()]
	return CardRegistry.create_card(template.card_name, card_rarity)

# Create a random card from all available cards
static func create_random_card(card_rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	var all_cards = CardRegistry.get_all_card_names()
	if all_cards.is_empty():
		return null
	
	var card_name = all_cards[randi() % all_cards.size()]
	return CardRegistry.create_card(card_name, card_rarity)
