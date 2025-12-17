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

# Create starter collection - 4 of each common card with minimum values
# If there aren't enough cards, keep generating the same cards until we reach 
# minimum deck size (20)
static func create_starter_collection() -> Array[CardData]:
	var collection: Array[CardData] = []
	const MIN_DECK_SIZE = 20
	const CARDS_PER_TYPE = 4
	
	# Get all available card names from registry
	var all_card_names = CardRegistry.get_all_card_names()
	
	if all_card_names.is_empty():
		push_warning("[ExampleCards] No cards available in registry!")
		return collection
	
	# Create 4 copies of each card in common rarity with minimum values
	for card_name in all_card_names:
		for i in CARDS_PER_TYPE:
			var card = CardRegistry.create_card_with_minimum_values(
				card_name, 
				CardData.Rarity.COMMON
			)
			if card:
				collection.append(card)
	
	# If we don't have enough cards for a minimum deck, keep generating the same cards
	if collection.size() < MIN_DECK_SIZE:
		var msg = "[ExampleCards] Only %d cards available, need %d. Generating duplicates..."
		print(msg % [collection.size(), MIN_DECK_SIZE])
		var card_index = 0
		while collection.size() < MIN_DECK_SIZE:
			if all_card_names.size() == 0:
				push_error("[ExampleCards] No cards available to generate!")
				break
			
			var card_name = all_card_names[card_index % all_card_names.size()]
			var card = CardRegistry.create_card_with_minimum_values(
				card_name, 
				CardData.Rarity.COMMON
			)
			if card:
				collection.append(card)
			card_index += 1
	
	var msg2 = "[ExampleCards] Created starter collection with %d cards (minimum %d required)"
	print(msg2 % [collection.size(), MIN_DECK_SIZE])
	return collection

# ============================================
# UTILITY METHODS
# ============================================

# Create a random card of a specific element
static func create_random_card_by_element(
	element: CardData.ElementType, 
	card_rarity: CardData.Rarity = CardData.Rarity.COMMON
) -> CardData:
	var cards_of_element = CardRegistry.get_cards_by_element(element)
	if cards_of_element.is_empty():
		return null
	
	var template = cards_of_element[randi() % cards_of_element.size()]
	return CardRegistry.create_card(template.card_name, card_rarity)

# Create a random card from all available cards
static func create_random_card(
	card_rarity: CardData.Rarity = CardData.Rarity.COMMON
) -> CardData:
	var all_cards = CardRegistry.get_all_card_names()
	if all_cards.is_empty():
		return null
	
	var card_name = all_cards[randi() % all_cards.size()]
	return CardRegistry.create_card(card_name, card_rarity)
