extends Node2D

@export var score_label : Label
@export var money_label : RichTextLabel

@export var draw_deck_align : Panel
@export var discard_deck_align : Panel


@export var draw_deck : Button
@export var discard_deck : Button

@export var draw_button : Button
@export var go_button : Button
@export var discard_button : Button


@export var center_money_rect : Control

@export var draw_nb_left_label : Label
@export var card_tape_nb_left_label : Label

@export var tooltip_panel : Panel

@export var indic : Sprite2D
@export var small_indic : Sprite2D

@export var coin_zone : Control

@export var round_label : Label

@export var tape_panel : Panel
@export var shop_panels : HBoxContainer
@export var next_button : Button

@export var title_label : RichTextLabel
@export var title_elements : Array[Control]


func init_hand():
	globals.delete_elements(globals.ALIGN_TYPE.HELD_CARDS, true)
	#globals.init_align_randomly(globals.ALIGN_TYPE.HELD_CARDS, globals.start_held_card_nb, true, true)
	for i in range(globals.start_held_card_nb):
		globals.draw_card.emit()
		await get_tree().create_timer(.1 / globals.user_play_speed).timeout
	globals.score = 0
	globals.score_mantissa = 0
	#for card in globals.held_cards:
		#print(card.draggable.align_zone.align_type)

func init_rules():
	for rule in globals.starting_rules:
		globals.add_rule(rule)
		audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)
		await get_tree().create_timer(.1 / globals.user_play_speed).timeout
		globals.update_content_align.emit(globals.ALIGN_TYPE.CARD_RULES)

func start_level():
	tape_panel.visible = true
	var start_tape_position = tape_panel.position
	tape_panel.position = Vector2(-1600,start_tape_position.y)
	var tween = get_tree().create_tween()
	tween.tween_property(tape_panel, "position", start_tape_position, 0.5 / globals.user_play_speed).set_trans(Tween.TRANS_EXPO)
	
	next_button.visible = false
	var start_shop_position = shop_panels.position
	tween = get_tree().create_tween()
	tween.tween_property(shop_panels, "position", Vector2(600,start_shop_position.y), 0.5 / globals.user_play_speed).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(shop_panels, "visible", false, 0.)
	tween.tween_property(shop_panels, "position", start_shop_position, 0.)
	tween.tween_callback(globals.delete_elements.bind(globals.ALIGN_TYPE.SHOP))
	
	
	draw_deck.disabled = false
	discard_deck.disabled = false
	globals.rules = []
	for c in globals.card_rules:
		$"../CanvasLayer".remove_child(c)
	globals.card_rules = []
	init_rules()
	draw_button.disabled = false
	go_button.disabled = false
	discard_button.visible = true
	globals.nb_draw_left = globals.start_nb_draws
	init_hand()
	globals.level_id += 1

func end_level():
	var start_tape_position = tape_panel.position
	var tween = get_tree().create_tween()
	tween.tween_property(tape_panel, "position", Vector2(600,start_tape_position.y), 0.5 / globals.user_play_speed).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(tape_panel, "visible", false, 0.)
	tween.tween_property(tape_panel, "position", start_tape_position, 0.)
	tween.tween_callback(globals.delete_elements.bind(true).bind(globals.ALIGN_TYPE.PLAYED_CARDS))
	
	shop_panels.visible = true
	next_button.visible = true
	var start_shop_position = shop_panels.position
	shop_panels.position = Vector2(-1800,start_shop_position.y)
	tween = get_tree().create_tween()
	tween.tween_property(shop_panels, "position", start_shop_position, 0.5 / globals.user_play_speed).set_trans(Tween.TRANS_EXPO)
	
	draw_button.disabled = true
	go_button.disabled = true
	discard_button.visible = false
	globals.delete_elements(globals.ALIGN_TYPE.DISCARD_DECK, true)
	for i in range(5):
		globals.draw_shop.emit()
		await get_tree().create_timer(.1 / globals.user_play_speed).timeout
	


func _process(delta):
	if globals.current_element_hovered != null && !globals.current_element_hovered.mouse_hovered:
		globals.current_element_hovered = null
		
	if globals.current_element_hovered == null:
		globals.is_card_tooltip_active = false
	
	if globals.score > 1e10:
		globals.score_mantissa += 5
		globals.score /= 1e5
	var s = str(int(globals.score))
	if globals.score > 1e6 || globals.score_mantissa > 0:
		s = str(globals.score).split(".")[0]
		s = s[0] + "." + s[1] + s[2] + "e" + str(len(s) - 1 + globals.score_mantissa)
	score_label.text =  s
	
	
	money_label.text = "[wave amp=200 freq=2 connected=0][center][font_size=300]%s[img=375]res://sprites//coin.png[/img]" % str(globals.money)
	round_label.text = "ROUND\n" + str(globals.level_id)
	card_tape_nb_left_label.text = str(globals.max_nb_tape - len(globals.played_cards))
	draw_nb_left_label.text = str(globals.nb_draw_left)
	if globals.is_computing_score && len(globals.played_cards) > 0:
		small_indic.visible = true
		indic.visible = true
		indic.global_position = (indic.global_position + globals.played_cards[min(globals.current_scoring_card_id, len(globals.played_cards) - 1)].global_position + Vector2(0,150)) / 2
		small_indic.global_position = (small_indic.global_position + globals.card_rules[min(globals.current_rule_card_id, len(globals.card_rules) - 1)].global_position + Vector2(0,75)) / 2
	else:
		small_indic.visible = false
		indic.visible = false
	
	tooltip_panel.visible = globals.is_card_tooltip_active
	tooltip_panel.global_position = globals.card_tooltip_pos - tooltip_panel.size * tooltip_panel.scale / 2
	tooltip_panel.get_child(0).text = "[center]" + globals.card_tooltip_text
	if globals.card_tooltip_title != "":
		tooltip_panel.get_child(1).visible = true
		tooltip_panel.get_child(1).get_child(0).text = "[center]" + globals.card_tooltip_title
	else:
		tooltip_panel.get_child(1).visible = false
	globals.is_card_tooltip_active = false
	
func _ready():
	globals.draw_card.connect(_on_draw_card)
	globals.draw_shop.connect(_on_draw_shop)
	globals.score_tween.connect(_on_score_tween)
	globals.instanciate_card.connect(_on_instanciate_card)
	globals.delete_card.connect(_on_delete_card)
	globals.change_money.connect(_on_change_money)
	globals.init_align_randomly(globals.ALIGN_TYPE.FULL_DECK)
	tape_panel.visible = false
	draw_button.disabled = true
	go_button.disabled = true
	discard_button.visible = false
	shop_panels.visible = false
	globals.card_rules = []
	for rule in globals.starting_rules:
		globals.add_rule(rule)
	globals.update_content_align.emit(globals.ALIGN_TYPE.CARD_RULES)
	draw_deck.disabled = true
	discard_deck.disabled = true
	title_label.visible = true
	for el in title_elements:
		el.visible = true
	
func _on_instanciate_card(c):
	$"../CanvasLayer".add_child(c)

func _on_next_button_button_up():
	start_level()

func _on_draw_card():
	globals.init_align_randomly(globals.ALIGN_TYPE.HELD_CARDS, 1,false, true)
	audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)

func _on_draw_shop():
	globals.init_align_randomly(globals.ALIGN_TYPE.SHOP, 1,false, false)
	audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)


func add_money(delay, amount=1):
	await get_tree().create_timer(delay).timeout
	globals.money += amount

func get_money(pos, amount, radius):
	var mult = 1
	if amount > 300:
		mult = amount / 300
	amount /= mult
	for i in range(amount):
		globals.create_droplet.emit(pos + radius * randf() * Vector2.from_angle(randf() * 2. * PI), .8)
		await get_tree().create_timer(5. / (float(amount) * float(amount) * globals.user_play_speed)).timeout
		audio_manager.play_sound(audio_manager.SOUNDS.INCOMING_COIN, float(i)/float(amount) * audio_manager.MAX_PITCH)
	if amount > 0:
		await get_tree().create_timer(.5 / globals.user_play_speed).timeout
	for i in range(amount):
		globals.move_droplet.emit(center_money_rect.global_position + center_money_rect.size /2,.8, true)
		add_money(.8, (randi() % 3 + 3) * mult)
		await get_tree().create_timer(5. / (float(amount) * float(amount) * globals.user_play_speed)).timeout
		audio_manager.play_sound(audio_manager.SOUNDS.GET_COIN, float(i)/float(amount) * audio_manager.MAX_PITCH)


func _on_end_turn_button_button_up():
	globals.is_computing_score = true
	await globals.compute_score()
	await get_money(get_viewport_rect().size/2, globals.nb_activation, 100)
	globals.play_speed = globals.user_play_speed
	globals.is_computing_score = false
	end_level()


func _on_draw_deck_button_up():
	draw_deck_align.visible = true
	globals.showing_deck = true
	for card in globals.full_deck:
		$"../CanvasLayer".add_child(card)
		card.position = draw_deck.global_position
	globals.update_content_align.emit(globals.ALIGN_TYPE.FULL_DECK)
	audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)

func _input(event):
	if event is InputEventMouseButton && globals.showing_deck:
		await get_tree().create_timer(.1).timeout
		draw_deck_align.visible = false
		globals.showing_deck = false
		for card in globals.full_deck:
			$"../CanvasLayer".remove_child(card)
		audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)
	
	if event is InputEventMouseButton && globals.showing_discard:
		await get_tree().create_timer(.1).timeout
		discard_deck_align.visible = false
		globals.showing_discard = false
		for card in globals.discard_deck:
			$"../CanvasLayer".remove_child(card)
		audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)


func _on_discard_deck_button_up():
	discard_deck_align.visible = true
	globals.showing_discard = true
	for card in globals.discard_deck:
		$"../CanvasLayer".add_child(card)
		card.position = discard_deck.global_position
	globals.update_content_align.emit(globals.ALIGN_TYPE.DISCARD_DECK)
	audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)


func _on_draw_button_button_up():
	if globals.nb_draw_left > 0:
		var nb_to_draw = globals.start_held_card_nb - len(globals.held_cards)
		while nb_to_draw > 0:
			globals.draw_card.emit()
			await get_tree().create_timer(.1 / globals.user_play_speed).timeout
			nb_to_draw -= 1
		globals.nb_draw_left -= 1


func _on_play_button_button_up() -> void:
	for el in title_elements:
		el.visible = false
	var start_title_position = title_label.position
	var tween = get_tree().create_tween()
	tween.tween_property(title_label, "position", Vector2(start_title_position.x,-500), 0.4 / globals.user_play_speed).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(title_label, "visible", false, 0.)
	tween.tween_property(title_label, "position", start_title_position, 0.)
	start_level()



func _on_discard_button_button_up():
	while len(globals.held_cards) > 0:
		var card = globals.held_cards[0]
		globals.held_cards.erase(card)
		globals.discard_deck.append(card)
		$"../CanvasLayer".remove_child(card)
		globals.update_content_align.emit(globals.ALIGN_TYPE.HELD_CARDS)
		globals.update_content_align.emit(globals.ALIGN_TYPE.DISCARD_DECK)
		audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)
		audio_manager.play_sound(audio_manager.SOUNDS.DISCARD)
		await get_tree().create_timer(.1 / globals.user_play_speed).timeout
	

func _on_delete_card(c):
	$"../CanvasLayer".remove_child(c)


func _on_score_tween():
	var tween = get_tree().create_tween()
	tween.tween_property(score_label, "scale", score_label.scale*1.5, 0.3 / globals.play_speed).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(score_label, "scale", score_label.scale, 0.3 / globals.play_speed).set_trans(Tween.TRANS_EXPO)


func _on_change_money(amount, obj):
	await get_tree().create_timer(.1 / (globals.user_play_speed)).timeout
	if amount < 0:
		add_money(.0, abs(amount - (amount/3)*3) * sign(amount))
	for i in range(abs(amount)/3):
		if amount < 0:
			add_money(.0, 3 * sign(amount))
		if amount >= 0:
			globals.create_droplet.emit(obj.position, .0)
		else:
			globals.create_droplet.emit(center_money_rect.global_position + center_money_rect.size /2, .0)
		if amount < 0:
			globals.move_droplet.emit(obj.position, .8, true)
		else:
			globals.move_droplet.emit(center_money_rect.global_position + center_money_rect.size /2, .8, true)
		if amount >= 0:
			add_money(.8, 3 * sign(amount))
		await get_tree().create_timer(5. / (float(amount) * float(amount) * globals.user_play_speed)).timeout
		audio_manager.play_sound(audio_manager.SOUNDS.INCOMING_COIN, float(i)/float(amount) * audio_manager.MAX_PITCH)
	if amount >= 0:
		add_money(.8, abs(amount - (amount/3)*3) * sign(amount))
