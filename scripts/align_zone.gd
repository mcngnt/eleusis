extends Panel



@export var align_type = globals.ALIGN_TYPE.NONE

@export var is_frozen = false
@export var is_paid = false
@export var is_closed = false

@export var max_nb = 999

@export var align_on_x = true
@export var margin : float
@export var relative_margin = 1.0

@export var is_stack_style = false
@export var best_items_number = 10

@export var show_preview = false
@export var tex_preview : Texture
var preview_sprites : Array[Sprite2D]


var accepted_drag_type = []


var elements = []

func get_global_elements():
	match align_type:
		globals.ALIGN_TYPE.HELD_CARDS:
			return globals.held_cards
		globals.ALIGN_TYPE.SHOP:
			return globals.shop
		globals.ALIGN_TYPE.PLAYED_CARDS:
			return globals.played_cards
		globals.ALIGN_TYPE.FULL_DECK:
			return globals.full_deck
		globals.ALIGN_TYPE.DISCARD_DECK:
			return globals.discard_deck
		globals.ALIGN_TYPE.CARD_RULES:
			return globals.card_rules
		_:
			return null

func _ready():
	globals.element_held.connect(_on_element_held)
	globals.update_content_align.connect(_on_update_content)
	match align_type:
		globals.ALIGN_TYPE.HELD_CARDS:
			accepted_drag_type = [globals.DRAG_TYPE.CARD]
		globals.ALIGN_TYPE.PLAYED_CARDS:
			accepted_drag_type = [globals.DRAG_TYPE.CARD]
		globals.ALIGN_TYPE.SHOP:
			accepted_drag_type = [globals.DRAG_TYPE.CARD]
		globals.ALIGN_TYPE.FULL_DECK:
			accepted_drag_type = [globals.DRAG_TYPE.CARD]
		globals.ALIGN_TYPE.DISCARD_DECK:
			accepted_drag_type = [globals.DRAG_TYPE.CARD]
		globals.ALIGN_TYPE.CARD_RULES:
			accepted_drag_type = [globals.DRAG_TYPE.CARD]
		_:
			pass
	if show_preview:
		for i in range(best_items_number):
			var s = Sprite2D.new()
			s.texture = tex_preview
			s.z_index = 1
			s.scale = Vector2(1.7,1.7)
			add_child(s)
			preview_sprites.append(s)

func update_globals():
	match align_type:
		globals.ALIGN_TYPE.HELD_CARDS:
			globals.held_cards = elements.duplicate()
		globals.ALIGN_TYPE.SHOP:
			globals.shop = elements.duplicate()
		globals.ALIGN_TYPE.PLAYED_CARDS:
			globals.played_cards = elements.duplicate()
		_:
			pass

func update_elements():
	match align_type:
		globals.ALIGN_TYPE.HELD_CARDS:
			elements = globals.held_cards.duplicate()
		globals.ALIGN_TYPE.SHOP:
			elements = globals.shop.duplicate()
		globals.ALIGN_TYPE.PLAYED_CARDS:
			elements = globals.played_cards.duplicate()
		globals.ALIGN_TYPE.FULL_DECK:
			elements = globals.full_deck.duplicate()
		globals.ALIGN_TYPE.DISCARD_DECK:
			elements = globals.discard_deck.duplicate()
		globals.ALIGN_TYPE.CARD_RULES:
			elements = globals.card_rules.duplicate()
		_:
			pass

func get_anchor_points(nb):
	var anchors = []
	var offset_vec = Vector2(1,0)
	if align_on_x == false:
		offset_vec = Vector2(0,1)
	
	var zone_len = size.x * 4 * margin
	if align_on_x == false:
		zone_len = size.y * 4 * margin
	if !is_stack_style:
		zone_len -= zone_len / (nb * relative_margin)
	
	var step = zone_len / (nb - 1)
	if is_stack_style:
		step = zone_len / (max(best_items_number, nb) - 1)
	
	if nb == 0:
		return []
	if nb == 1:
		if is_stack_style:
			return [[global_position - (zone_len/2) * offset_vec / 2 + size/2, 0]]
		return [[global_position + size / 2, 0]]

	for i in range(nb):
		anchors.append([global_position + (-zone_len/2 + step * i) * offset_vec / 2 + size / 2, i])
	return anchors


func get_closest_anchor_id(e, anchors):
	var id_closest = 0
	var dist_closest = INF
	for a in anchors:
		var d = (a[0] - e.position).length()
		if d < dist_closest:
			dist_closest = d
			id_closest = a[1]
	if is_frozen:
		return len(anchors) - 1
	return id_closest
	

func arrange_elements():
	var anchors = get_anchor_points(len(elements))
	var id_closest = -1
	if globals.is_element_held && globals.held_element.draggable.drag_type in accepted_drag_type && len(elements) < max_nb && !is_closed:
		anchors = get_anchor_points(len(elements) + 1)
		id_closest = get_closest_anchor_id(globals.held_element, anchors)

	var j = 0
	for i in range(len(anchors)):
		if i == id_closest:
			continue
		elements[j].draggable.target_position = anchors[i][0]
		#elements[j].z_index = 10 + (len(elements) - j)*5
		elements[j].z_index = 10 + j * 5
		elements[j].draggable.number = j
		j += 1

func try_add_element(e):
	if !(e in elements):
		var i = get_closest_anchor_id(e, get_anchor_points(len(elements) + 1))
		e.draggable.is_frozen = is_frozen
		elements.insert(i, e)
		update_globals()
		if align_type == globals.ALIGN_TYPE.PLAYED_CARDS:
			audio_manager.play_sound(audio_manager.SOUNDS.ACCEPT)


func _process(delta):
	if align_type == globals.ALIGN_TYPE.FULL_DECK && !globals.showing_deck:
		pass
	else:
		arrange_elements()
		if show_preview:
			var anchors = get_anchor_points(best_items_number)
			for i in range(best_items_number):
				if i >= len(elements):
					preview_sprites[i].visible = true
					preview_sprites[i].global_position = anchors[i][0]
				else:
					preview_sprites[i].visible = false


func _on_mouse_entered():
	if globals.is_element_held && globals.held_element.draggable.drag_type in accepted_drag_type && len(elements) < max_nb && !is_closed:
		globals.held_element.draggable.align_zone = self

func erase_element(e):
	elements.erase(e)
	update_globals()

func _on_element_held():
	if globals.held_element in elements:
		erase_element(globals.held_element)

func _on_update_content(atype):
	if atype == align_type:
		for el in get_global_elements():
			el.draggable.align_zone = self
			el.draggable.is_frozen = is_frozen
			el.draggable.is_paid = is_paid
			el.draggable.dragging = false
		update_elements()
	
