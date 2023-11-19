extends Camera2D

signal camer_moved

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			position -= event.relative
			emit_signal("camer_moved")
