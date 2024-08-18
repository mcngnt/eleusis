extends Camera2D

#var mouse_start_pos
#var screen_start_position
#
#var dragging = false


#func set_camera_transform():
	#position = $"../level".get_middle_pos()
	#var zoom_level_x = float(get_viewport().size.x) /  $"../level".get_size().x
	#var zoom_level_y = float(get_viewport().size.y) /  $"../level".get_size().y
	#var zoom_level = min(zoom_level_x, zoom_level_y) * 0.5
	#zoom = Vector2(zoom_level,zoom_level)


func _process(delta):
	pass
	#set_camera_transform()

#func _input(event):
	#if event.is_action("drag"):
		#if event.is_pressed():
			#mouse_start_pos = event.position
			#screen_start_position = position
			#dragging = true
		#else:
			#dragging = false
	#elif event is InputEventMouseMotion and dragging:
		#position =  (mouse_start_pos - event.position) * (1/float(zoom.x)) + screen_start_position
