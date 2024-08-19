extends Node2D

const DROPLET = preload("res://scenes/droplet.tscn")

var moving_droplets = []

func _ready():
	globals.create_droplet.connect(_on_create_droplet)
	globals.move_droplet.connect(_on_move_droplet)

func _on_create_droplet(pos, delay):
	var droplet = DROPLET.instantiate()
	add_child(droplet)
	var tween = get_tree().create_tween()
	droplet.position = Vector2.from_angle(randf() * 2. * PI) * get_viewport().size.x + Vector2(get_viewport().size / 2) + Vector2(0,50)
	tween.tween_property(droplet, "position", pos, delay).set_trans(Tween.TRANS_EXPO)
	
	#droplet.position = pos
	#tween.tween_property(droplet, "drop_scale", 1., delay).set_trans(Tween.TRANS_EXPO)
	
func _on_move_droplet(target_pos, delay, destroy=false):
	var i = 0
	while get_child(i) in moving_droplets:
		i += 1
	var current_droplet = get_child(i)
	moving_droplets.append(current_droplet)
	var tween = get_tree().create_tween()
	tween.tween_property(current_droplet, "position", target_pos, delay).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(current_droplet, "scale", Vector2(), delay).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	moving_droplets.erase(current_droplet)
	if destroy:
		current_droplet.queue_free()
