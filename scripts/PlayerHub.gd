extends Control

# Scene references
const MAIN_MENU_SCENE = "res://scenes/MainMenu.tscn"
const GAME_SCENE = "res://main.tscn"

# UI node references
var save_info_label: Label
var back_button: Button
var collection_tab: Button
var decks_tab: Button
var content_container: MarginContainer
var collection_view: VBoxContainer
var deck_list_view: VBoxContainer
var current_deck_label: Label
var play_button: Button
var deck_editor_popup: CanvasLayer

# Track current tab
enum Tab { COLLECTION, DECKS }
var current_tab: Tab = Tab.COLLECTION

func _ready():
	# Get node references
	save_info_label = $MarginContainer/MainLayout/Header/SaveInfoLabel
	back_button = $MarginContainer/MainLayout/Header/BackButton
	collection_tab = $MarginContainer/MainLayout/TabBar/CollectionTab
	decks_tab = $MarginContainer/MainLayout/TabBar/DecksTab
	content_container = $MarginContainer/MainLayout/ContentPanel
	collection_view = $MarginContainer/MainLayout/ContentPanel/ClipContainer/CollectionView
	deck_list_view = $MarginContainer/MainLayout/ContentPanel/ClipContainer/DeckListView
	current_deck_label = $MarginContainer/MainLayout/Footer/CurrentDeckLabel
	play_button = $MarginContainer/MainLayout/Footer/PlayButton
	deck_editor_popup = $DeckEditorPopup
	
	# Connect button signals
	back_button.pressed.connect(_on_back_pressed)
	collection_tab.pressed.connect(_on_collection_tab_pressed)
	decks_tab.pressed.connect(_on_decks_tab_pressed)
	play_button.pressed.connect(_on_play_pressed)
	
	# Connect deck list view signals
	if deck_list_view.has_signal("edit_deck_requested"):
		deck_list_view.edit_deck_requested.connect(_on_edit_deck_requested)
	if deck_list_view.has_signal("deck_selected"):
		deck_list_view.deck_selected.connect(_on_deck_selected)
	
	# Connect deck editor signals
	var deck_editor = deck_editor_popup.get_node_or_null("DeckEditor")
	if deck_editor and deck_editor.has_signal("deck_saved"):
		deck_editor.deck_saved.connect(_on_deck_saved)
	if deck_editor and deck_editor.has_signal("editor_closed"):
		deck_editor.editor_closed.connect(_on_editor_closed)
	
	# Check if there's an active match to resume
	if SaveManager and SaveManager.current_save_data:
		if SaveManager.current_save_data.has_match_to_resume():
			print("[PlayerHub] Found in-progress match - transitioning to game scene")
			# Wait a frame to ensure everything is initialized
			await get_tree().process_frame
			get_tree().change_scene_to_file(GAME_SCENE)
			return
	
	# Initialize display
	_update_save_info()
	_update_current_deck_display()
	_switch_to_tab(Tab.COLLECTION)
	
	print("[PlayerHub] Initialized")

func _update_save_info():
	if not SaveManager or not SaveManager.current_save_data:
		save_info_label.text = "No Save Loaded"
		return
	
	var save_data = SaveManager.current_save_data
	var player_name = save_data.player_name
	if player_name == "New Game" or player_name == "":
		player_name = "Save Slot %d" % save_data.slot_number
	
	var collection_size = save_data.card_collection.size()
	var deck_count = save_data.decks.size()
	
	save_info_label.text = "%s | %d Cards | %d Decks" % [player_name, collection_size, deck_count]

func _update_current_deck_display():
	if not SaveManager or not SaveManager.current_save_data:
		current_deck_label.text = "No Deck Selected"
		play_button.disabled = true
		return
	
	var save_data = SaveManager.current_save_data
	var deck_name = save_data.current_deck_name
	var deck_size = save_data.current_deck.size()
	
	if deck_name == "" or deck_size == 0:
		current_deck_label.text = "No Deck Selected"
		play_button.disabled = true
	else:
		current_deck_label.text = "Current Deck: %s (%d cards)" % [deck_name, deck_size]
		# Only enable play if deck meets minimum size
		play_button.disabled = deck_size < 20

func _switch_to_tab(tab: Tab):
	current_tab = tab
	
	# Update tab button states
	collection_tab.button_pressed = (tab == Tab.COLLECTION)
	decks_tab.button_pressed = (tab == Tab.DECKS)
	
	# Toggle content visibility
	collection_view.visible = (tab == Tab.COLLECTION)
	deck_list_view.visible = (tab == Tab.DECKS)
	
	# Refresh the visible view
	if tab == Tab.COLLECTION and collection_view.has_method("refresh"):
		collection_view.refresh()
	elif tab == Tab.DECKS and deck_list_view.has_method("refresh"):
		deck_list_view.refresh()

func _on_back_pressed():
	print("[PlayerHub] Returning to main menu")
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_collection_tab_pressed():
	_switch_to_tab(Tab.COLLECTION)

func _on_decks_tab_pressed():
	_switch_to_tab(Tab.DECKS)

func _on_play_pressed():
	if not SaveManager or not SaveManager.current_save_data:
		push_error("[PlayerHub] Cannot play - no save data")
		return
	
	var save_data = SaveManager.current_save_data
	if save_data.current_deck.size() < 20:
		push_error("[PlayerHub] Cannot play - deck has less than 20 cards")
		return
	
	print("[PlayerHub] Starting game with deck: %s" % save_data.current_deck_name)
	
	# Clear any previous match state when starting a new game
	save_data.clear_match_state()
	SaveManager.save_game()
	
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_edit_deck_requested(deck_name: String):
	print("[PlayerHub] Edit deck requested: %s" % deck_name)
	_open_deck_editor(deck_name)

func _on_deck_selected(deck_name: String):
	print("[PlayerHub] Deck selected: %s" % deck_name)
	_update_current_deck_display()

func _open_deck_editor(deck_name: String = ""):
	var deck_editor = deck_editor_popup.get_node_or_null("DeckEditor")
	if deck_editor and deck_editor.has_method("open"):
		deck_editor.open(deck_name)
	deck_editor_popup.visible = true

func _on_deck_saved():
	print("[PlayerHub] Deck saved")
	_update_save_info()
	_update_current_deck_display()
	if deck_list_view.has_method("refresh"):
		deck_list_view.refresh()

func _on_editor_closed():
	deck_editor_popup.visible = false

func open_deck_editor_for_new_deck():
	_open_deck_editor("")
