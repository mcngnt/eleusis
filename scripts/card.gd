extends Node2D

enum CARD_TYPE {NONE, BASIC}

enum CARD_RANK {ZERO,ACE,TWO,THREE, FOUR,FIVE,SIX,SEVEN,EIGHT,NINE,TEN,JACK,QUEEN,KING}

enum CARD_COLOR {RED,BLACK}

@onready var draggable = $draggable
@onready var sprite_2d = $Sprite2D
@onready var rich_text_label = $VBoxContainer/RichTextLabel
@onready var price_label = $price_label
@onready var select = $select
@onready var color_rect = $ColorRect

const drag_type = globals.DRAG_TYPE.CARD


@export var type = CARD_TYPE.NONE
@export var rank = CARD_RANK.ZERO
@export var color = CARD_COLOR.RED


var price = 5

func get_value():
	match rank:
		CARD_RANK.ACE:
			return 11
		CARD_RANK.JACK:
			return 10
		CARD_RANK.QUEEN:
			return 10
		CARD_RANK.KING:
			return 10
		_:
			return rank

func get_rank_name():
	return CARD_RANK.keys()[rank].to_lower()

func get_ordering():
	match rank:
		CARD_RANK.ACE:
			return 14
		_:
			return rank


func init_attributes(r, c):
	type = CARD_TYPE.BASIC
	color = c
	rank = r

func trigger():
	pass


func play_card_tween():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", self.scale*1.5, 0.5 / globals.play_speed).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "scale", self.scale, 0.5 / globals.play_speed).set_trans(Tween.TRANS_EXPO)
	return tween

func sample_randomly():
	type = CARD_TYPE.values()[randi() % (CARD_TYPE.size() - 1) + 1]
	rank = CARD_RANK.values()[randi() % (CARD_RANK.size())]
	color = CARD_COLOR.values()[randi() % (CARD_COLOR.size())]
	price = randi() % 20 + 10


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
	return str(CARD_RANK.keys()[rank]) + " " + str(CARD_COLOR.keys()[color])
#
func _ready():
	#rich_text_label.text = get_header_text() + get_descr()
	var path = "res://sprites/cards/%s_%s.png" % [str(rank), str(CARD_COLOR.keys()[color]).to_lower()]
	sprite_2d.texture = load(path)
	


func _process(delta):
	price_label.visible = draggable.is_paid
	price_label.text = str(price) + " G"
	if draggable.mouse_hovered:
		color_rect.get_tooltip()
