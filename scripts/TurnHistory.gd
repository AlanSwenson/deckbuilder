extends Control

@onready var history_label: RichTextLabel = $VBoxContainer/HistoryLabel
@onready var close_button: Button = $VBoxContainer/CloseButton

var history_lines: Array[String] = []

func _ready():
	# Start with a header
	add_line("=== Turn History ===", Color.WHITE)
	
	# Connect close button
	close_button.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	hide()

func add_line(text: String, _color: Color = Color.WHITE):
	history_lines.append(text)
	_update_display()

func add_damage_event(slot: int, card_name: String, damage: int, target: String, blocked: int = 0):
	var text = "Slot %d: %s → %d DMG to %s" % [slot, card_name, damage, target]
	if blocked > 0:
		text += " (Blocked: %d)" % blocked
	add_line(text, Color.RED)

func add_heal_event(slot: int, card_name: String, heal: int, target: String):
	var text = "Slot %d: %s → +%d Heal to %s" % [slot, card_name, heal, target]
	add_line(text, Color.GREEN)

func add_block_event(slot: int, card_name: String, block: int):
	var text = "Slot %d: %s → %d Block" % [slot, card_name, block]
	add_line(text, Color.CYAN)

func add_slot_cards(slot: int, player_card_name: String, enemy_card_name: String):
	# Log what cards are in this slot - each on separate line
	var player_text = player_card_name if player_card_name else "Empty"
	var enemy_text = enemy_card_name if enemy_card_name else "Empty"
	
	# Player card on first line
	var player_line = "Slot %d: Player : %s" % [slot, player_text]
	add_line(player_line, Color.WHITE)
	
	# Enemy card on second line
	var enemy_line = "Slot %d: Enemy : %s" % [slot, enemy_text]
	add_line(enemy_line, Color.WHITE)

func clear_history():
	history_lines.clear()
	add_line("=== Turn History ===", Color.WHITE)

func _update_display():
	if not history_label:
		return
	
	# Build the rich text with colors
	var rich_text = ""
	for line in history_lines:
		# Simple color coding - if line contains certain keywords, color it
		if "DMG" in line or "damage" in line.to_lower():
			rich_text += "[color=#ff6666]" + line + "[/color]\n"
		elif "Heal" in line or "heal" in line.to_lower():
			rich_text += "[color=#66ff66]" + line + "[/color]\n"
		elif "Block" in line or "block" in line.to_lower():
			rich_text += "[color=#66ccff]" + line + "[/color]\n"
		elif "Empty" in line or "empty" in line.to_lower():
			rich_text += "[color=#888888]" + line + "[/color]\n"
		elif "Player : " in line or "Enemy : " in line:
			# Slot cards line - highlight player/enemy names (with spaces around colon)
			rich_text += "[color=#ffffff]" + line + "[/color]\n"
		elif "===" in line:
			rich_text += "[color=#ffffff]" + line + "[/color]\n"
		else:
			rich_text += "[color=#cccccc]" + line + "[/color]\n"
	
	history_label.text = rich_text
	
	# Auto-scroll to bottom
	call_deferred("_scroll_to_bottom")

func _scroll_to_bottom():
	if history_label:
		history_label.scroll_to_line(history_lines.size())

