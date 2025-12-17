extends Node2D
class_name GameState

# HP tracking
var player_hp: int = 100
var enemy_hp: int = 100

# Hand size management
var max_hand_size: int = 10  # Default max hand size (can be modified by cards)

# Game state
enum GameStatus {
	PLAYING,
	PLAYER_WON,
	PLAYER_LOST
}

var game_status: GameStatus = GameStatus.PLAYING

# Signals
signal player_hp_changed(new_hp: int)
signal enemy_hp_changed(new_hp: int)
signal game_won()
signal game_lost()

# UI references
var player_hp_label: Label = null
var enemy_hp_label: Label = null
var game_over_label: Label = null
var game_over_canvas: CanvasLayer = null

func _ready() -> void:
	# Create UI labels for HP display
	_create_hp_ui()
	update_hp_display()
	
	# Check for saved game state and load it
	call_deferred("_check_and_load_saved_state")

func _check_and_load_saved_state() -> void:
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	if SaveManager and SaveManager.current_save_data:
		if SaveManager.current_save_data.has_match_to_resume():
			print("[GameState] Found saved match state, loading...")
			var game_state_saver = GameStateSaver.new()
			get_tree().current_scene.add_child(game_state_saver)
			var success = await game_state_saver.load_game_state(SaveManager.current_save_data)
			game_state_saver.queue_free()
			
			if success:
				print("[GameState] Successfully loaded saved match state")
				# Update hand positions after loading
				var player_hand = get_parent().get_node_or_null("PlayerHand")
				if player_hand and player_hand.has_method("update_hand_positions"):
					player_hand.update_hand_positions()
				
				var enemy_hand = get_parent().get_node_or_null("EnemyHand")
				if enemy_hand and enemy_hand.has_method("update_hand_positions"):
					enemy_hand.update_hand_positions()
				
				# Autosave after loading to ensure state is persisted
				if SaveManager:
					await get_tree().create_timer(0.5).timeout  # Wait for everything to settle
					SaveManager.autosave_game_state()
			else:
				print("[GameState] Failed to load saved match state, starting new game")
				# Clear invalid match state
				if SaveManager and SaveManager.current_save_data:
					SaveManager.current_save_data.clear_match_state()
		else:
			print("[GameState] No saved match state, starting new game")
			# Ensure match state is clear for new games
			if SaveManager and SaveManager.current_save_data:
				SaveManager.current_save_data.clear_match_state()
			
			# Autosave initial state after hands are dealt
			await get_tree().create_timer(2.0).timeout  # Wait for hands to be dealt
			if SaveManager:
				SaveManager.autosave_game_state()

func _create_hp_ui() -> void:
	# Player HP label (bottom left)
	player_hp_label = Label.new()
	player_hp_label.name = "PlayerHPLabel"
	add_child(player_hp_label)
	player_hp_label.position = Vector2(20, 20)
	player_hp_label.add_theme_font_size_override("font_size", 32)
	player_hp_label.add_theme_color_override("font_color", Color.WHITE)
	player_hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	player_hp_label.add_theme_constant_override("outline_size", 4)
	
	# Enemy HP label (top right)
	enemy_hp_label = Label.new()
	enemy_hp_label.name = "EnemyHPLabel"
	add_child(enemy_hp_label)
	enemy_hp_label.position = Vector2(20, 80)
	enemy_hp_label.add_theme_font_size_override("font_size", 32)
	enemy_hp_label.add_theme_color_override("font_color", Color.WHITE)
	enemy_hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	enemy_hp_label.add_theme_constant_override("outline_size", 4)
	
	# Game over label (centered, initially hidden) - use CanvasLayer to ensure it's on top
	game_over_canvas = CanvasLayer.new()
	game_over_canvas.name = "GameOverCanvas"
	add_child(game_over_canvas)
	
	game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_canvas.add_child(game_over_label)
	game_over_label.position = Vector2(600, 400)
	game_over_label.size = Vector2(400, 200)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 48)
	game_over_label.add_theme_color_override("font_color", Color.YELLOW)
	game_over_label.add_theme_color_override("font_outline_color", Color.BLACK)
	game_over_label.add_theme_constant_override("outline_size", 6)
	game_over_label.visible = false

func update_hp_display() -> void:
	if player_hp_label:
		player_hp_label.text = "Player HP: " + str(player_hp)
	if enemy_hp_label:
		enemy_hp_label.text = "Enemy HP: " + str(enemy_hp)

# Apply damage to player
func damage_player(amount: int) -> void:
	# Allow damage to be applied even if game ended (for visual consistency in slot resolution)
	# Only apply if game is still playing
	if game_status == GameStatus.PLAYING:
		player_hp -= amount
		player_hp = max(0, player_hp)  # Don't go below 0
		player_hp_changed.emit(player_hp)
		update_hp_display()
		
		print("[GameState] Player took ", amount, " damage. HP: ", player_hp)
		
		# Check for lose condition
		if player_hp <= 0:
			lose_game()
	else:
		var msg = "Player would take %d damage, but game is not playing (status: %d)"
		print(msg % [amount, game_status])

# Apply damage to enemy
func damage_enemy(amount: int) -> void:
	# Allow damage to be applied even if game ended (for visual consistency in slot resolution)
	# Only apply if game is still playing
	if game_status == GameStatus.PLAYING:
		enemy_hp -= amount
		enemy_hp = max(0, enemy_hp)  # Don't go below 0
		enemy_hp_changed.emit(enemy_hp)
		update_hp_display()
		
		print("[GameState] Enemy took ", amount, " damage. HP: ", enemy_hp)
		
		# Check for win condition
		if enemy_hp <= 0:
			win_game()
	else:
		var msg = "Enemy would take %d damage, but game is not playing (status: %d)"
		print(msg % [amount, game_status])

# Heal player
func heal_player(amount: int) -> void:
	if game_status != GameStatus.PLAYING:
		return
	
	player_hp += amount
	player_hp_changed.emit(player_hp)
	update_hp_display()
	
	print("[GameState] Player healed ", amount, ". HP: ", player_hp)

# Heal enemy
func heal_enemy(amount: int) -> void:
	if game_status != GameStatus.PLAYING:
		return
	
	enemy_hp += amount
	enemy_hp_changed.emit(enemy_hp)
	update_hp_display()
	
	print("[GameState] Enemy healed ", amount, ". HP: ", enemy_hp)

# Win condition triggered
func win_game() -> void:
	if game_status != GameStatus.PLAYING:
		return
	
	game_status = GameStatus.PLAYER_WON
	game_won.emit()
	show_game_over("VICTORY!", Color.GREEN)
	print("[GameState] Player won!")
	
	# Clear match state when game ends
	_clear_match_state()

# Lose condition triggered
func lose_game() -> void:
	if game_status != GameStatus.PLAYING:
		return
	
	game_status = GameStatus.PLAYER_LOST
	game_lost.emit()
	show_game_over("DEFEAT!", Color.RED)
	print("[GameState] Player lost!")
	
	# Clear match state when game ends
	_clear_match_state()

# Clear saved match state (called when game ends)
func _clear_match_state() -> void:
	if SaveManager and SaveManager.current_save_data:
		SaveManager.current_save_data.clear_match_state()
		SaveManager.save_game()
		print("[GameState] Cleared match state from save")

# Show game over message
func show_game_over(message: String, color: Color) -> void:
	if game_over_label:
		game_over_label.text = message
		game_over_label.add_theme_color_override("font_color", color)
		game_over_label.visible = true

# Check if game is still playing
func is_game_playing() -> bool:
	return game_status == GameStatus.PLAYING
