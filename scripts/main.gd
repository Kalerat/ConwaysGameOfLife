extends Node2D


@export var node_size: int = 15:
	set = set_node_size
@export var border_size: int = 1:
	set = set_border_size
var combined_size: int = node_size + border_size
	
@export var active_node_color = Color(1,0,0)
@export var inactive_node_color = Color(1, 1, 1)

var sim_speed = 1.0
var time_since_last_update = 0.0
var is_running = false
var do_step = false
var sim_step_counter = 0

var bounding_rect: Rect2i
var active_nodes = []
var visible_nodes = Dictionary()
var center_node: Vector2i
var camera_moved = false


func _ready():
	combined_size = node_size + border_size
	center_node = get_node_id_from_coords($Camera.position)
	recalc_bounding_rect()
	get_tree().get_root().size_changed.connect(_resize)
	

func _resize():
	recalc_bounding_rect()
	
# Reset the grid to an empty state
func reset_board():
	active_nodes.clear()
	sim_step_counter = 0
	$UI/ButtonControler/StepCounterLabel.text = str(sim_step_counter)
	$UI/ButtonControler/PlayButton.text = "Start"
	$UI/ButtonControler/PlayButton.button_pressed = false
	is_running = false
	queue_redraw()

# Translate viewport coordinates into a resolution and node size independent node index
func get_node_id_from_coords(pos: Vector2i) -> Vector2i:
	var res: Vector2i
	res.x = pos.x / combined_size
	res.y = pos.y / combined_size
	
	return res

# Translates a node index into viewport coordinates
func get_coords_from_node_id(node_id: Vector2i) -> Vector2i:
	var res: Vector2i
	res.x = node_id.x * combined_size
	res.y = node_id.y * combined_size
	return res
	
	
func _process(delta):
	time_since_last_update += delta 
	if(time_since_last_update >= sim_speed && is_running == true) || do_step == true:
		time_since_last_update = 0
		sim_step_counter += 1
		$UI/ButtonControler/StepCounterLabel.text = str(sim_step_counter)

		var nodes_to_check = active_nodes.duplicate()
		var node_change_queue = Dictionary()
		
		while !nodes_to_check.is_empty():
			var neighbors = []
			var active_neighbor_count = 0;
			var node = get_coords_from_node_id(nodes_to_check.front())
			nodes_to_check.pop_front()
			
			neighbors.append(Vector2i(node.x-combined_size, node.y-combined_size))
			neighbors.append(Vector2i(node.x, node.y-combined_size))
			neighbors.append(Vector2i(node.x+combined_size, node.y-combined_size))
			neighbors.append(Vector2i(node.x-combined_size, node.y))
			neighbors.append(Vector2i(node.x+combined_size, node.y))
			neighbors.append(Vector2i(node.x-combined_size, node.y+combined_size))
			neighbors.append(Vector2i(node.x, node.y+combined_size))
			neighbors.append(Vector2i(node.x+combined_size, node.y+combined_size))
			
			for neighbor in neighbors:
				if(active_nodes.has(get_node_id_from_coords(neighbor))):
					active_neighbor_count += 1
				elif active_nodes.has(get_node_id_from_coords(node)):
					if(nodes_to_check.find(get_node_id_from_coords(neighbor)) == -1):
						nodes_to_check.append(get_node_id_from_coords(neighbor))
			var is_active_node = active_nodes.has(get_node_id_from_coords(node))
			if(active_neighbor_count == 2 && is_active_node):
				pass
			elif(active_neighbor_count == 3 && !is_active_node):
				node_change_queue[node] = true
			elif(active_neighbor_count == 3):
				pass
			elif is_active_node:	
				node_change_queue[node] = false
		
		for node in node_change_queue:
			if(node_change_queue[node] == true):
				active_nodes.append(get_node_id_from_coords(node))
			else:
				var index = active_nodes.find(get_node_id_from_coords(node))
				if(index != -1):
					active_nodes.pop_at(active_nodes.find(get_node_id_from_coords(node)))
		do_step = false
		queue_redraw()
			


func _draw():
	
	#Draw Background
	draw_rect(bounding_rect, inactive_node_color)
	var line_count_x = (bounding_rect.size.x / combined_size)
	var line_count_y = (bounding_rect.size.y / combined_size)
	
	#Draw the grid
	for i in line_count_x:
		var line_from = Vector2i(bounding_rect.position.x + (i*combined_size), bounding_rect.position.y)
		var line_to	= 	Vector2i(bounding_rect.position.x + (i*combined_size), bounding_rect.position.y + bounding_rect.size.y)
		draw_line(line_from, line_to, Color(0,0,0),border_size)
	for i in line_count_y:
		var line_from = Vector2i(bounding_rect.position.x, bounding_rect.position.y + (i*combined_size))
		var line_to	= 	Vector2i(bounding_rect.position.x + bounding_rect.size.x, bounding_rect.position.y + (i*combined_size))
		draw_line(line_from, line_to, Color(0,0,0),border_size)
		
	#Color all the active nodes
	for node in active_nodes:
		var pos: Vector2 = get_coords_from_node_id(node)
		#Hack to fix the weirdness of Godot's custom shape rendering
		#Try to find an actual fix for this?
		pos += Vector2(0.5, 0.5)
		var size = Vector2i(node_size, node_size)
		var node_rect = Rect2(pos, size)
		draw_rect(node_rect, active_node_color)



func set_node_size(value):
	node_size = value
	recalc_bounding_rect()


func set_border_size(value):
	border_size = value
	recalc_bounding_rect()
	

# Returns the corner coordinates of the node the supplied coordinates fall into
func calculate_closest_node_corner(pos_x: int, pos_y: int) -> Vector2i:
	var res: Vector2i
	if(pos_x >= 0):
		res.x = (pos_x - (pos_x % combined_size))
	else:
		var tmp = abs(pos_x)
		var tmp2 = tmp + (combined_size - (tmp % combined_size))
		res.x = tmp2 * (-1)
	
	if(pos_y >= 0):
		res.y = pos_y - (pos_y % combined_size)
	else:
		var tmp = abs(pos_y)
		var tmp2 = tmp + (combined_size - (tmp % combined_size))
		res.y = tmp2 * (-1)
	
	return res
	
	
# Calculates a Border around the Viewport
# Used to only draw visible nodes
func recalc_bounding_rect():
	combined_size = node_size + border_size
	if(!camera_moved):
		$Camera.position = get_coords_from_node_id(center_node)
	else:
		camera_moved = false
	var camera_pos: Vector2i = round($Camera.position)
	var viewport_size: Vector2i = round(get_viewport_rect().size)
	var camera_corner_pos = Vector2i(camera_pos.x - (viewport_size.x / 2), camera_pos.y - (viewport_size.y / 2))
	
	# Calculate the last visible node in the upper left corner
	# This makes sure we cover the upper and left border of the screen
	var bounding_corner = calculate_closest_node_corner(camera_corner_pos.x, camera_corner_pos.y)
	bounding_rect.position.x = bounding_corner.x
	bounding_rect.position.y = bounding_corner.y
	bounding_rect.size = viewport_size
	
	#Increase the size of the Bounding Rectangle by one node to fully conver the right and lower side of the screen
	bounding_rect.size.x += combined_size
	bounding_rect.size.y += combined_size
	queue_redraw()


func _on_camera_camer_moved():
	center_node = get_node_id_from_coords(round($Camera.position))
	camera_moved = true
	recalc_bounding_rect()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			var mouse_pos: Vector2i = round(get_global_mouse_position())
			var clicked_node = calculate_closest_node_corner(mouse_pos.x, mouse_pos.y)
			var node_id = get_node_id_from_coords(clicked_node)
			var index = active_nodes.find(node_id)
			if(index == -1):
				active_nodes.append(node_id)
			else:
				active_nodes.pop_at(index)
			sim_step_counter = 0
			queue_redraw()
	elif event is InputEventKey:
		if(event.is_action_pressed("toggle_fullscreen")):
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		



func _on_button_toggled(button_pressed):
	if button_pressed:
		$UI/ButtonControler/PlayButton.text = "Stop"
		is_running = true
	else:
		$UI/ButtonControler/PlayButton.text = "Start"
		is_running = false
	


func _on_single_step_pressed():
	do_step = true
	is_running = false
	$UI/ButtonControler/PlayButton.text = "Start"


func _on_sim_speed_value_changed(value):
	sim_speed = 1 / value


func _on_sim_speed_ready():
	var slider_value = $UI/ButtonControler/SimSpeedSlider.value
	sim_speed = 1 / slider_value


func _on_reset_button_pressed():
	reset_board()


func _on_node_size_slider_value_changed(value):
	set_node_size(value)
