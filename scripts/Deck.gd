extends Node2D

var deck_count_label: Label = null
var player_deck: Node2D = null

func _ready() -> void:
	# Wait a frame to ensure PlayerDeck is initialized
	await get_tree().process_frame
	
	# Find PlayerDeck node
	player_deck = get_parent().get_node_or_null("PlayerDeck")
	if not player_deck:
		print("[Deck] ERROR: PlayerDeck not found!")
	
	# Create label for deck count
	deck_count_label = Label.new()
	add_child(deck_count_label)
	deck_count_label.name = "DeckCountLabel"
	deck_count_label.position = Vector2(-30, -120)  # Position above the deck
	deck_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_count_label.add_theme_font_size_override("font_size", 24)
	deck_count_label.add_theme_color_override("font_color", Color.WHITE)
	deck_count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	deck_count_label.add_theme_constant_override("outline_size", 4)
	
	# Update the count display
	update_deck_count()

func _process(_delta: float) -> void:
	# Update deck count every frame (could be optimized with signals later)
	if player_deck:
		update_deck_count()

func update_deck_count() -> void:
	if not deck_count_label:
		return
	
	# Make sure we have a reference to PlayerDeck
	if not player_deck:
		player_deck = get_parent().get_node_or_null("PlayerDeck")
	
	if player_deck and player_deck.has_method("get_deck_size"):
		var count = player_deck.get_deck_size()
		deck_count_label.text = str(count)
	else:
		deck_count_label.text = "?"
