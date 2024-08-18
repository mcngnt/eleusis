extends Node2D

#
#var size = 5
#var drops_pos = []
#var data = []
#
#var drop_scale = 1.

var uv_pos = Vector2()

var drawn = false

#func get_rnd_data():
	#return Vector3(randi() % 100, randf() * 0.001 + 0.001, randf() * 0.02 + 0.02)
#
#func _ready():	
	#data = []
	#for i in range(size):
		#drops_pos.append(Vector2())
		#data.append([get_rnd_data(),get_rnd_data()])
##
#
func _process(delta):
	position = uv_pos * Vector2(get_viewport().size)
	##position = get_viewport().get_mouse_position()
	#for i in range(size):
		#drops_pos[i] = position + Vector2(sin(Time.get_ticks_msec() * data[i][0].y + data[i][0].x) * data[i][0].z,sin(Time.get_ticks_msec() * data[i][1].y + data[i][1].x) * data[i][1].z)
