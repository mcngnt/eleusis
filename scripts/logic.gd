extends Node2D

@export var title_box : VBoxContainer

@export var score_label : Label
@export var money_label : RichTextLabel

@export var shop_box : HBoxContainer

@export var draw_deck_align : Panel
@export var discard_deck_align : Panel

@onready var timer = $Timer

@export var scoring_objects : Array[Control]

@export var draw_deck : Button
@export var discard_deck : Button

@export var draw_button : Button
@export var go_button : Button


@export var center_money_rect : Control

@export var draw_nb_left_label : Label
@export var card_tape_nb_left_label : Label

@export var tooltip_panel : Panel

@export var indic : Sprite2D

@export var coin_zone : Control

func init_hand():
	globals.delete_elements(globals.ALIGN_TYPE.HELD_CARDS, true)
	#globals.init_align_randomly(globals.ALIGN_TYPE.HELD_CARDS, globals.start_held_card_nb, true, true)
	for i in range(globals.start_held_card_nb):
		globals.draw_card.emit()
		await get_tree().create_timer(.1 / globals.play_speed).timeout
	globals.score = 0
	#for card in globals.held_cards:
		#print(card.draggable.align_zone.align_type)

func start_level():
	draw_deck.disabled = false
	discard_deck.disabled = false
	globals.rules = []
	for c in globals.card_rules:
		$"../CanvasLayer".remove_child(c)
	globals.card_rules = []
	globals.add_rule(globals.CARD_TYPE.X_OF_KIND)
	globals.add_rule(globals.CARD_TYPE.FLUSH)
	globals.add_rule(globals.CARD_TYPE.STRAIGHT)
	globals.add_rule(globals.CARD_TYPE.ANY)
	globals.update_content_align.emit(globals.ALIGN_TYPE.CARD_RULES)
	for e in scoring_objects:
		e.visible = true
	draw_button.disabled = false
	go_button.disabled = false
	shop_box.visible = false
	globals.delete_elements(globals.ALIGN_TYPE.SHOP)
	globals.nb_draw_left = globals.start_nb_draws
	init_hand()
	globals.level_id += 1

func end_level():
	for e in scoring_objects:
		e.visible = false
	draw_button.disabled = true
	go_button.disabled = true
	shop_box.visible = true
	globals.delete_elements(globals.ALIGN_TYPE.PLAYED_CARDS, true)
	globals.delete_elements(globals.ALIGN_TYPE.DISCARD_DECK, true)
	#globals.init_align_randomly(globals.ALIGN_TYPE.SHOP, 3)
	for i in range(3):
		globals.draw_shop.emit()
		await get_tree().create_timer(.1 / globals.play_speed).timeout



#func _on_change_score(new_score):
	#score_label.text = "Score : " + str(new_score)

func _process(delta):
	score_label.text =  str(globals.score)
	money_label.text = "[center][font_size=300]%s[img=375]res://sprites//coin.png[/img]" % str(globals.money)
	card_tape_nb_left_label.text = str(globals.max_nb_tape - len(globals.played_cards))
	draw_nb_left_label.text = str(globals.nb_draw_left)
	if globals.is_computing_score && len(globals.played_cards) > 0:
		indic.visible = true
		indic.global_position = (indic.global_position + globals.played_cards[min(globals.current_scoring_card_id, len(globals.played_cards) - 1)].global_position + Vector2(0,150)) / 2
	else:
		indic.visible = false
		if len(globals.played_cards) > 0:
			indic.global_position = globals.played_cards[0].global_position + Vector2(0,200)
	
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
	globals.init_align_randomly(globals.ALIGN_TYPE.FULL_DECK)
	for e in scoring_objects:
		e.visible = false
	draw_button.disabled = true
	go_button.disabled = true
	globals.card_rules = []
	globals.add_rule(globals.CARD_TYPE.X_OF_KIND)
	globals.add_rule(globals.CARD_TYPE.FLUSH)
	globals.add_rule(globals.CARD_TYPE.STRAIGHT)
	globals.add_rule(globals.CARD_TYPE.ANY)
	globals.update_content_align.emit(globals.ALIGN_TYPE.CARD_RULES)
	draw_deck.disabled = true
	discard_deck.disabled = true
	


func _on_next_button_button_up():
	start_level()

func _on_draw_card():
	globals.init_align_randomly(globals.ALIGN_TYPE.HELD_CARDS, 1,false, true)
	audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)

func _on_draw_shop():
	globals.init_align_randomly(globals.ALIGN_TYPE.SHOP, 1,false, true)
	audio_manager.play_sound(audio_manager.SOUNDS.CARD, 1., -10)

func _on_timer_timeout():
	globals.is_computing_score = false
	end_level()

func add_money(delay, amount=1):
	await get_tree().create_timer(delay).timeout
	globals.money += amount

func get_money(pos, amount, radius):
	await get_tree().create_timer(.4 / globals.play_speed).timeout
	for i in range(amount):
		globals.create_droplet.emit(pos + radius * randf() * Vector2.from_angle(randf() * 2. * PI), .6 / globals.play_speed)
		await get_tree().create_timer(.04 / globals.play_speed).timeout
		audio_manager.play_sound(audio_manager.SOUNDS.INCOMING_COIN, float(i)/float(amount) * audio_manager.MAX_PITCH)
	await get_tree().create_timer(.2 / globals.play_speed).timeout
	for i in range(amount):
		globals.move_droplet.emit(center_money_rect.global_position + center_money_rect.size /2,.6 / globals.play_speed, true)
		add_money(.5 / globals.play_speed, randi() % 2 + 2)
		await get_tree().create_timer(.1 / globals.play_speed).timeout
		audio_manager.play_sound(audio_manager.SOUNDS.GET_COIN, float(i)/float(amount) * audio_manager.MAX_PITCH)
	await get_tree().create_timer(.5 / globals.play_speed).timeout


func _on_end_turn_button_button_up():
	globals.is_computing_score = true
	await globals.compute_score()
	await get_money(coin_zone.global_position, randi() % 10 + 20, 100)
	timer.start()


#func _on_discard_button_button_up():
	#var nb_dis = 0
	#for card in globals.held_cards.duplicate():
		#if card.draggable.is_selected:
			#nb_dis += 1
			#card.draggable.is_selected = false
			#globals.held_cards.erase(card)
			#globals.update_content_align.emit(globals.ALIGN_TYPE.HELD_CARDS)
			#$"../CanvasLayer".remove_child(card)
			#globals.discard_deck.append(card)
	#for i in range(nb_dis):
		#globals.draw_card.emit()
			#



func _on_draw_deck_button_up():
	draw_deck_align.visible = true
	globals.showing_deck = true
	for card in globals.full_deck:
		$"../CanvasLayer".add_child(card)
		card.position = draw_deck.global_position
	globals.update_content_align.emit(globals.ALIGN_TYPE.FULL_DECK)

func _input(event):
	if event is InputEventMouseButton && globals.showing_deck:
		await get_tree().create_timer(.1).timeout
		draw_deck_align.visible = false
		globals.showing_deck = false
		for card in globals.full_deck:
			$"../CanvasLayer".remove_child(card)
	
	if event is InputEventMouseButton && globals.showing_discard:
		await get_tree().create_timer(.1).timeout
		discard_deck_align.visible = false
		globals.showing_discard = false
		for card in globals.discard_deck:
			$"../CanvasLayer".remove_child(card)


func _on_discard_deck_button_up():
	discard_deck_align.visible = true
	globals.showing_discard = true
	for card in globals.discard_deck:
		$"../CanvasLayer".add_child(card)
		card.position = discard_deck.global_position
	globals.update_content_align.emit(globals.ALIGN_TYPE.DISCARD_DECK)


func _on_draw_button_button_up():
	if globals.nb_draw_left > 0:
		var nb_to_draw = globals.start_held_card_nb - len(globals.held_cards)
		while nb_to_draw > 0:
			globals.draw_card.emit()
			await get_tree().create_timer(.1 / globals.play_speed).timeout
			nb_to_draw -= 1
		globals.nb_draw_left -= 1


func _on_play_button_button_up() -> void:
	title_box.visible = false
	start_level()
