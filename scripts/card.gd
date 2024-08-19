extends Node2D



@onready var draggable = $draggable
@onready var sprite_2d = $Sprite2D
@onready var price_label = $price_label
@onready var select = $select
@onready var shadow = $Sprite2D/Shadow

@onready var top_panel_pos = $top_panel_pos
@onready var bot_panel_pos = $bot_panel_pos



const drag_type = globals.DRAG_TYPE.CARD


@export var type = globals.CARD_TYPE.NONE
@export var rank = globals.CARD_RANK.ZERO
@export var color = globals.CARD_COLOR.RED


var price = 5

func get_value():
	match rank:
		globals.CARD_RANK.ACE:
			return 11
		globals.CARD_RANK.JACK:
			return 10
		globals.CARD_RANK.QUEEN:
			return 10
		globals.CARD_RANK.KING:
			return 10
		_:
			return rank

func get_rank_name():
	return globals.CARD_RANK.keys()[rank].to_lower()

func get_ordering():
	match rank:
		globals.CARD_RANK.ACE:
			return 14
		_:
			return rank


func init_attributes(r, c):
	type = globals.CARD_TYPE.BASIC
	color = c
	rank = r



func trigger():
	match type:
		globals.CARD_TYPE.BASIC:
			return
	globals.add_rule(type)
	#globals.rules.append(type)
	globals.update_content_align.emit(globals.ALIGN_TYPE.CARD_RULES)


func play_card_tween():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", self.scale*1.5, 0.5 / globals.play_speed).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "scale", self.scale, 0.5 / globals.play_speed).set_trans(Tween.TRANS_EXPO)
	return tween

func sample_randomly():
	type = globals.CARD_TYPE.values()[randi() % (globals.CARD_TYPE.size() - 1) + 1]
	rank = globals.CARD_RANK.values()[randi() % (globals.CARD_RANK.size())]
	color = globals.CARD_COLOR.values()[randi() % (globals.CARD_COLOR.size())]
	match type:
		globals.CARD_TYPE.RED_FLAG:
			color = globals.CARD_COLOR.RED
		globals.CARD_TYPE.BLACK_SWAN:
			color = globals.CARD_COLOR.BLACK
	price = randi() % 10 + 30


#func get_wisp_text(text = "wisp"):
	#var base_tag = ["[wave amp=100 freq=4]", "[/wave]"]
	#var color_tag = ["",""]
	#match wisp_color:
		#globals.WISP_COLOR.BICHROMATIC:
			#color_tag = ["[gradient span=0.1]", "[/gradient]"]
		#_:
			#color_tag = ["[color=%s]" % globals.WISP_SCREEN_COLOR[wisp_color].to_html(), "[/color]"]
	#
	#var size_tag = ["", ""]
	#match wisp_weight:
		#globals.WISP_WEIGHT.LIGHTWEIGHT:
			#size_tag = ["[font_size=80]", "[/font_size]"]
		#globals.WISP_WEIGHT.HEAVY:
			#size_tag = ["[font_size=250]", "[/font_size]"]
		#_:
			#pass
	#
	#return base_tag[0] + color_tag[0] + size_tag[0] + text + size_tag[1] + color_tag[1] + base_tag[1] + "\n\n"

func get_header_text():
	return "[font_size=120][center][outline_size=100][outline_color=#000]"

func get_descr():
	return str(globals.CARD_RANK.keys()[rank]) + " " + str(globals.CARD_COLOR.keys()[color])
#
func _ready():
	var path = globals.get_card_path(type, rank, color)
	sprite_2d.texture = load(path)
	shadow.texture = load(path)
	#top_panel.get_child(0).text = globals.get_rule_desc(type)
	


func _process(delta):
	price_label.visible = draggable.is_paid
	price_label.text = str(price) + " G"
	if draggable.mouse_hovered && draggable == globals.current_element_hovered && !draggable.dragging:
		if draggable.align_zone.align_type == globals.ALIGN_TYPE.HELD_CARDS:
			globals.card_tooltip_pos = top_panel_pos.global_position
		else:
			globals.card_tooltip_pos = bot_panel_pos.global_position
		globals.card_tooltip_text = globals.get_rule_desc(type)
		globals.is_card_tooltip_active = true
