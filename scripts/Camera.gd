extends Camera2D

signal camer_moved

var zoom_min = Vector2(0.05, 0.05)
var zoom_max = Vector2(2, 2)
var zoom_speed = 10.0

func _unhandled_input(event):
#	if Input.is_action_pressed("zoom_in"):
#		zoom = Vector2(zoom.x*(1.0+1.0/zoom_speed), zoom.y*(1.0+1.0/zoom_speed))
#	if Input.is_action_pressed("zoom_out"):
#		zoom = Vector2(zoom.x*(1.0-1.0/zoom_speed), zoom.y*(1.0-1.0/zoom_speed))
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			position -= event.relative
			emit_signal("camer_moved")
