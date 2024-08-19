extends Panel


var rects : Array[TextureRect] = []

@export var margin : float

func get_anchor_points(nb):
	var anchors = []
	var offset_vec = Vector2(1,0)
	var zone_len = size.x * 4 * margin
	var step = zone_len / (nb - 1)
	if nb == 0:
		return []
	if nb == 1:
		return [[global_position + size / 2, 0]]
	for i in range(nb):
		anchors.append([global_position + (-zone_len/2 + step * i) * offset_vec / 2 + size / 2, i])
	return anchors



func _process(delta):
	if len(globals.rules) != len(rects):
		for rect in rects:
			remove_child(rect)
		rects = []
		for card_type in globals.rules:
			var r = TextureRect.new()
			r.texture = load(globals.get_card_path(card_type))
			r.scale = Vector2(1.25,1.25)
			rects.append(r)
		for i in range(len(rects)):
			add_child(rects[i])
	var anchors = get_anchor_points(len(rects))
	for i in range(len(rects)):
		rects[i].global_position = anchors[i][0] - rects[i].texture.get_size() * rects[i].scale / 2
	
