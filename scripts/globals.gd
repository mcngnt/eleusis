extends Node

enum DRAG_TYPE {NONE, CARD, ARTIFACT}
enum ALIGN_TYPE {NONE, ARTIFACTS, HELD_CARDS, SHOP, FULL_DECK, PLAYED_CARDS, DISCARD_DECK}
enum COMBO_TYPE {ANY, X_OF_KIND, FLUSH, STRAIGHT}
enum COMBO_MODE {ADD, MULT}

#Minimum number of cards, Base score, Combo mode
var combo_stats = {COMBO_TYPE.ANY : [],COMBO_TYPE.X_OF_KIND : [2, 20, COMBO_MODE.MULT], COMBO_TYPE.FLUSH : [3, 10, COMBO_MODE.ADD], COMBO_TYPE.STRAIGHT : [2, 20, COMBO_MODE.ADD]}

signal element_held
signal update_content_align(align_type)
signal changed_score(new_score)
signal draw_card

signal create_droplet(pos, delay)
signal move_droplet(target_pos, delay)

const CARD = preload("res://scenes/card.tscn")
const SCORE_EFFECT = preload("res://scenes/score_effect.tscn")

var score = 0

var money = 0

var held_cards = []
var shop = []
var full_deck = []
var played_cards = []
var discard_deck = []

var play_speed = 1

var showing_deck = false
var showing_discard = false

var held_element = null
var is_element_held = false


var start_held_card_nb = 7
var start_nb_draws = 4
var max_nb_tape = 7

var level_id = 1
var nb_draw_left

var is_computing_score = false

var current_element_hovered = null

var current_scoring_card_id = 0

func compute_score():
	current_scoring_card_id = 0
	var triggered_cards = []
	while current_scoring_card_id < len(played_cards):
		var card = played_cards[current_scoring_card_id]
		triggered_cards.push_front(card)
		for combo in COMBO_TYPE.values():
			var bonus = 0
			var last_card = card
			var count = 0
			for prev_card in triggered_cards:
				match combo:
					COMBO_TYPE.ANY:
						bonus = card.get_value()
						break
					COMBO_TYPE.X_OF_KIND:
						if prev_card != last_card && last_card.rank != prev_card.rank:
							break
					COMBO_TYPE.FLUSH:
						if prev_card != last_card && last_card.color != prev_card.color:
							break
					COMBO_TYPE.STRAIGHT:
						if prev_card != last_card && last_card.get_ordering() - 1 != prev_card.get_ordering():
							break
				count += 1
				last_card = prev_card
			if combo != COMBO_TYPE.ANY && count >= combo_stats[combo][0]:
				match combo_stats[combo][2]:
					COMBO_MODE.ADD:
						bonus = combo_stats[combo][1] * (count - combo_stats[combo][0] + 1)
					COMBO_MODE.MULT:
						bonus = combo_stats[combo][1] * 2 ** (count - combo_stats[combo][0])
			if bonus > 0:
				score += bonus
				var effect = SCORE_EFFECT.instantiate()
				$"../game/CanvasLayer".add_child(effect)
				effect.position = card.global_position + Vector2(0,-200)
				var name = "none"
				match combo:
					COMBO_TYPE.ANY:
						name = "any " + card.get_rank_name()
					COMBO_TYPE.X_OF_KIND:
						name = str(count) + " of a kind"
					_:
						name = COMBO_TYPE.keys()[combo].to_lower() + " " + str(count)
				effect.launch(bonus, "+", name)
				await card.play_card_tween().finished
		
		card.trigger()
		current_scoring_card_id += 1


func delete_elements(align_type, sample_from=false):
	var el = []
	match align_type:
		ALIGN_TYPE.SHOP:
			el = shop.duplicate()
			shop = []
		ALIGN_TYPE.HELD_CARDS:
			el = held_cards.duplicate()
			held_cards = []
		ALIGN_TYPE.PLAYED_CARDS:
			el = played_cards.duplicate()
			played_cards = []
		ALIGN_TYPE.DISCARD_DECK:
			el = discard_deck.duplicate()
			discard_deck = []
	globals.update_content_align.emit(align_type)
	for d in el:
		if sample_from:
			$"../game/CanvasLayer".remove_child(d)
			full_deck.append(d)
		else:
			d.queue_free()
		

func init_align_randomly(align_type, nb = 0,delete_elements=true, sample_from=false, in_scene=true):
	
	if align_type == ALIGN_TYPE.FULL_DECK:
		var el = []
		for r in range(1,14):
			for c in range(2):
				var e = CARD.instantiate()
				e.init_attributes(r, c)
				el.append(e)
		full_deck = el.duplicate()
		return
	
	var prefabs = [null]
	match align_type:
		ALIGN_TYPE.HELD_CARDS:
			prefabs = [CARD]
		ALIGN_TYPE.SHOP:
			prefabs = [CARD]
		_:
				pass
	var el = []
	for i in range(nb):
		var e = null
		if !sample_from:
			e = prefabs.pick_random().instantiate()
			e.sample_randomly()
			if in_scene:
				$"../game/CanvasLayer".add_child(e)
				e.position = $"../game/logic".draw_deck.global_position
			el.append(e)
		else:
			if len(full_deck) == 0 && len(discard_deck) > 0:
				delete_elements(ALIGN_TYPE.DISCARD_DECK, true)
			if len(full_deck) > 0:
				e = full_deck.pick_random()
				full_deck.erase(e)
				$"../game/CanvasLayer".add_child(e)
				e.position = $"../game/logic".draw_deck.global_position
				el.append(e)
	
				
	match align_type:
		ALIGN_TYPE.HELD_CARDS:
			if delete_elements:
				held_cards = el.duplicate()
			else:
				held_cards += el.duplicate()
		ALIGN_TYPE.SHOP:
			if delete_elements:
				shop = el.duplicate()
			else:
				shop += el.duplicate()
		_:
				pass
	update_content_align.emit(align_type)
