extends Control

@onready var history_label: RichTextLabel = $HistoryLabel

var history_lines: Array[String] = []

func _ready():
	# Start with a header
	add_line("=== Turn History ===", Color.WHITE)

func add_line(text: String, color: Color = Color.WHITE):
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

