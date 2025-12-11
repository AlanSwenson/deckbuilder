extends CanvasLayer
@onready var close_button = $CenterContainer/VBoxContainer/Button

func _ready():
	# Connect the close button
	close_button.pressed.connect(_on_close_pressed)
	
	# Start hidden
	hide()

func open():
	show()

func close():
	hide()

func _on_close_pressed():
	close()

# Optional: Press ESC to close
func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close()
