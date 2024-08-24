extends Node2D



@onready var draggable = $draggable
@onready var sprite_2d = $Sprite2D
@onready var select = $select
@onready var shadow = $Sprite2D/Shadow
@onready var rich_text_label = $RichTextLabel

@onready var top_panel_pos = $top_panel_pos
@onready var bot_panel_pos = $bot_panel_pos

@onready var score_particle = $score_particle


const drag_type = globals.DRAG_TYPE.CARD

var base_scale : Vector2


@export var type = globals.CARD_TYPE.NONE
@export var rank = globals.CARD_RANK.ZERO
@export var color = globals.CARD_COLOR.RED
@export var is_color_joker = false
@export var is_rank_joker = false

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



func trigger(create_rule, left_neighbour):
	match type:
		globals.CARD_TYPE.BASIC:
			pass
		globals.CARD_TYPE.GOLDEN_TICKET:
			globals.change_money.emit(50, self)
			
			await globals.launch_effect(self,50, "m", -1, globals.get_card_title(type))
		globals.CARD_TYPE.GROWTH_HORMONE:
			globals.max_nb_tape += 1
			await globals.launch_effect(self,1, "+", -1, globals.get_card_title(type))
		globals.CARD_TYPE.DOLLY:
			for i in range(2):
				var c = self.duplicate()
				globals.instanciate_card.emit(c)
				globals.held_cards.append(c)
				audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)
				await get_tree().create_timer(.1 / globals.play_speed).timeout
			globals.update_content_align.emit(globals.ALIGN_TYPE.HELD_CARDS)
			await globals.launch_effect(self,2, "+", -1, globals.get_card_title(type))
		globals.CARD_TYPE.BLANK_CARD:
			pass
			#if left_neighbour != null:
				#await globals.launch_effect(self,0, "c", -1, globals.get_card_title(type))
				#await left_neighbour.trigger(create_rule, self)
		_:
			if create_rule:
				globals.add_rule(type,self)
				globals.update_content_align.emit(globals.ALIGN_TYPE.CARD_RULES)


func play_card_tween():
	score_particle.emitting = true
	if globals.play_speed > 40:
		self.scale *= 1.5
		await get_tree().create_timer(1. / globals.play_speed).timeout
		return
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", self.scale*1.5, 0.5 / globals.play_speed).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "scale", self.scale, 0.5 / globals.play_speed).set_trans(Tween.TRANS_EXPO)
	
	
	await get_tree().create_timer(1. / globals.play_speed).timeout
	
	
	

func sample_randomly(card_type=globals.CARD_TYPE.NONE):
	if card_type == globals.CARD_TYPE.NONE:
		type = globals.CARD_TYPE.values()[randi() % (globals.CARD_TYPE.size() - 1) + 1]
	else:
		type = card_type
	rank = globals.CARD_RANK.values()[randi() % (globals.CARD_RANK.size())]
	color = globals.CARD_COLOR.values()[randi() % (globals.CARD_COLOR.size())]
	match type:
		globals.CARD_TYPE.RED_FLAG:
			color = 0
			rank = 6
		globals.CARD_TYPE.BLACK_SWAN:
			color = 1
			rank = 6
		globals.CARD_TYPE.STRAIGHT:
			color = 1
			rank = 8
		globals.CARD_TYPE.X_OF_KIND:
			color = 0
			rank = 2
		globals.CARD_TYPE.FLUSH:
			color = 0
			rank = 5
		globals.CARD_TYPE.ANY:
			color = 1
			rank = 1
		globals.CARD_TYPE.PAR:
			color = 0
			rank = 4
		globals.CARD_TYPE.CRESUS:
			color = 0
			rank = 7
		globals.CARD_TYPE.TALKING_HEAD:
			color = 1
			rank = 11
		globals.CARD_TYPE.PAREIDOLIA:
			color = 1
			rank = 13
		globals.CARD_TYPE.FIBONACCI:
			color = 0
			rank = 3
		globals.CARD_TYPE.GOLDEN_TICKET:
			color = 1
			rank = 5
		globals.CARD_TYPE.UNITY:
			color = 1
			rank = 1
		globals.CARD_TYPE.ARMY:
			color = 0
			rank = 8
		globals.CARD_TYPE.ETERNAL_RETURN:
			color = 0
			rank = 0
		globals.CARD_TYPE.GROWTH_HORMONE:
			color = 1
			rank = 9
		globals.CARD_TYPE.DOLLY:
			color = 1
		globals.CARD_TYPE.BLANK_CARD:
			color = 1
			rank = 0
			is_rank_joker = true
		globals.CARD_TYPE.ENCODING:
			color = 1
			rank = 12
		globals.CARD_TYPE.BOULDER:
			color = 1
			rank = 3
		globals.CARD_TYPE.PAY_TO_WIN:
			color = 0
			rank = 2
		globals.CARD_TYPE.PAY_TO_WIN:
			color = 0
			rank = 2
		globals.CARD_TYPE.INUMERATE:
			color = 1
			rank = 11
		globals.CARD_TYPE.THE_RIPPER:
			color = 1
			rank = 11
		globals.CARD_TYPE.POLYCEPHALY:
			color = 0
			rank = 12
	price = randi() % 10 + 30


func get_header_text():
	return "[font_size=120][center][outline_size=100][outline_color=#000]"

func get_descr():
	return str(globals.CARD_RANK.keys()[rank]) + " " + str(globals.CARD_COLOR.keys()[color])
#
func _ready():
	var path = globals.get_card_path(type, rank, color)
	sprite_2d.texture = load(path)
	shadow.texture = load(path)
	base_scale = scale

func _process(delta):
	rich_text_label.visible = draggable.is_paid
	rich_text_label.text = "[center][font_size=200]%s[img=200]res://sprites//coin.png[/img]" % str(price)
	if draggable.mouse_hovered && draggable == globals.current_element_hovered && !draggable.dragging:
		if draggable.align_zone.align_type == globals.ALIGN_TYPE.HELD_CARDS:
			globals.card_tooltip_pos = top_panel_pos.global_position
		else:
			globals.card_tooltip_pos = bot_panel_pos.global_position
		if draggable.align_zone.align_type == globals.ALIGN_TYPE.CARD_RULES:
			globals.card_tooltip_text = globals.get_rule_desc(type)
		else:
			globals.card_tooltip_text = globals.get_card_descr(self)
		globals.card_tooltip_title = globals.get_card_title(type)
		globals.is_card_tooltip_active = true
	if scale != base_scale:
		scale = base_scale
