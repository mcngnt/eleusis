extends ColorRect

#var droplets =  []
var nb_drop = 0
var drops_pos : PackedVector2Array = []
var drops_scale : PackedFloat32Array = []

@onready var droplet_manager = $"../../droplet_manager"


func _process(delta):
	var droplets = droplet_manager.get_children()
	nb_drop = 0
	if len(droplets) > 0:
		nb_drop = len(droplets) * droplets[0].size
	drops_pos.resize(nb_drop)
	drops_scale.resize(nb_drop)
	material.set_shader_parameter("nb_drop", nb_drop)
	var i = 0
	for droplet in droplets:
		for drop_pos in droplet.drops_pos:
			drops_pos[i] = drop_pos
			drops_scale[i] = droplet.drop_scale
			i += 1
	material.set_shader_parameter("positions", drops_pos)
	material.set_shader_parameter("scales", drops_scale)
