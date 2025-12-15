# Collection factory - creates starter collections using CardRegistry
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

# Create starter collection - 4 of each common card
static func create_starter_collection() -> Array[CardData]:
	var collection: Array[CardData] = []
	
	# Get all available card names from registry
	var all_card_names = CardRegistry.get_all_card_names()
	
	# Create 4 copies of each card in common rarity
	for card_name in all_card_names:
		for i in 4:
			var card = CardRegistry.create_card(card_name, CardData.Rarity.COMMON)
			if card:
				collection.append(card)
	
	print("[ExampleCards] Created starter collection with %d cards (4 of each)" % collection.size())
	return collection

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
