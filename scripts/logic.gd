extends Node2D


@export var score_label : Label
@export var money_label : RichTextLabel

@export var shop_box : HBoxContainer

@export var draw_deck_align : Panel
@export var discard_deck_align : Panel

@onready var timer = $Timer

@export var scoring_objects : Array[Control]

@export var starting_deck : Array[Node2D]

@export var draw_deck : Button
@export var discard_deck : Button

@export var draw_button : Button
@export var go_button : Button


@export var draw_nb_left_label : Label
@export var card_tape_nb_left_label : Label

@export var indic : Sprite2D

func init_hand():
	globals.delete_elements(globals.ALIGN_TYPE.HELD_CARDS, true)
	globals.init_align_randomly(globals.ALIGN_TYPE.HELD_CARDS, globals.start_held_card_nb, true, true)
	globals.score = 0
	#for card in globals.held_cards:
		#print(card.draggable.align_zone.align_type)

func start_level():
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
	globals.init_align_randomly(globals.ALIGN_TYPE.SHOP, 3)



#func _on_change_score(new_score):
	#score_label.text = "Score : " + str(new_score)

func _process(delta):
	score_label.text =  str(globals.score)
	money_label.text = "[center][font_size=16]%s[img=20]res://sprites//coin.png[/img]" % str(globals.money)
	card_tape_nb_left_label.text = "\n" + str(globals.max_nb_tape - len(globals.played_cards))
	draw_nb_left_label.text = "\n" + str(globals.nb_draw_left)
	if globals.is_computing_score && len(globals.played_cards) > 0:
		indic.visible = true
		indic.global_position = (indic.global_position + globals.played_cards[min(globals.current_scoring_card_id, len(globals.played_cards) - 1)].global_position + Vector2(0,200)) / 2
	else:
		indic.visible = false
		if len(globals.played_cards) > 0:
			indic.global_position = globals.played_cards[0].global_position + Vector2(0,200)
	
func _ready():
	globals.draw_card.connect(_on_draw_card)
	globals.init_align_randomly(globals.ALIGN_TYPE.FULL_DECK)
	start_level()
	


func _on_next_button_button_up():
	start_level()

func _on_draw_card():
	globals.init_align_randomly(globals.ALIGN_TYPE.HELD_CARDS, 1,false, true)

func _on_timer_timeout():
	globals.is_computing_score = false
	end_level()

func add_money(delay, amount=1):
	await get_tree().create_timer(delay).timeout
	globals.money += amount

func get_money(pos, amount, radius):
	await get_tree().create_timer(.2 / globals.play_speed).timeout
	for i in range(amount):
		globals.create_droplet.emit(pos + radius * randf() * Vector2.from_angle(randf() * 1. * PI), .3)
		await get_tree().create_timer(.02 / globals.play_speed).timeout
	await get_tree().create_timer(.1 / globals.play_speed).timeout
	for i in range(amount):
		globals.move_droplet.emit(Vector2(0.1,0.1),.3 / globals.play_speed, true)
		add_money(.3 / globals.play_speed, randi() % 2 + 2)
		await get_tree().create_timer(.1 / globals.play_speed).timeout
	await get_tree().create_timer(.5 / globals.play_speed).timeout


func _on_end_turn_button_button_up():
	globals.is_computing_score = true
	await globals.compute_score()
	await get_money(Vector2(0.5,0.5) , randi() % 10 + 20, .1)
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
			nb_to_draw -= 1
		globals.nb_draw_left -= 1
