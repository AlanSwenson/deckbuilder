extends Node2D

const HAND_COUNT = 10
const CARD_SCENE_PATH = "res://scenes/Card.tscn"
const CARD_WIDTH = 100
const HAND_Y_POSITION = 800

var player_hand = []
var center_screen_x

func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	
	var card_manager = $"../CardManager"
	var card_scene = preload(CARD_SCENE_PATH)
	for i in range(HAND_COUNT):
		var new_card = card_scene.instantiate()
		card_manager.add_child(new_card)
		new_card.name = "Card" + str(i)  # Give each card a unique name
		# Ensure the card is registered with CardManager for dragging
		card_manager.register_card(new_card)
		add_card_to_hand(new_card)
		
func add_card_to_hand(card):
	player_hand.insert(0, card)
	update_hand_positions()
		
func update_hand_positions():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		# Store starting position as meta data (proper way to attach data to nodes)
		card.set_meta("starting_position", new_position)
		animate_card_to_position(card, new_position)
		
func calculate_card_position(index):
	var total_width = (player_hand.size() -1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2	
	return x_offset

func animate_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.1)

# Remove a card from the hand and update positions to close the gap
func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions()
		print("[PlayerHand] Removed card from hand: ", card.name, " | Hand size: ", player_hand.size())
