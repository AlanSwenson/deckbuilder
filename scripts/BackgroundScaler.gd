extends Sprite2D

func _ready() -> void:
	# Wait a frame to ensure viewport is ready
	await get_tree().process_frame
	_update_scale()

func _update_scale() -> void:
	if not texture:
		return
	
	var viewport = get_viewport()
	# Use get_window().size for the actual window size, or get_visible_rect() for viewport
	var viewport_size = viewport.get_visible_rect().size
	# Fallback to window size if visible rect is invalid
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		var window = get_window()
		if window:
			viewport_size = window.size
		if viewport_size.x <= 0 or viewport_size.y <= 0:
			viewport_size = Vector2(1600, 1000)  # Final fallback size
	
	var texture_size = texture.get_size()
	if texture_size.x <= 0 or texture_size.y <= 0:
		return
	
	# Calculate scale to cover viewport (like CSS background-size: cover)
	# Scale by the larger ratio to ensure it covers the entire viewport
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	var cover_scale = max(scale_x, scale_y)
	
	# Add a small buffer to ensure no edges are visible
	cover_scale *= 1.01
	
	scale = Vector2(cover_scale, cover_scale)
	
	# Position the sprite at viewport center
	# Since we're in a Node2D parent (Main), position is relative to parent
	# The Main node should be at (0,0), so we center the background at viewport center
	position = viewport_size / 2.0
	
	# Debug output
	print("[BackgroundScaler] Viewport size: ", viewport_size)
	print("[BackgroundScaler] Texture size: ", texture_size)
	print("[BackgroundScaler] Scale: ", cover_scale)
	print("[BackgroundScaler] Position: ", position)
	print("[BackgroundScaler] Scaled texture size: ", texture_size * cover_scale)
