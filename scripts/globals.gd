extends Node

enum DRAG_TYPE {NONE, CARD, ARTIFACT}
enum ALIGN_TYPE {NONE, ARTIFACTS, HELD_CARDS, SHOP, FULL_DECK, PLAYED_CARDS, DISCARD_DECK, CARD_RULES}
enum COMBO_TYPE {ANY, X_OF_KIND, FLUSH, STRAIGHT}
enum COMBO_MODE {ADD, MULT}

enum CARD_TYPE {NONE, BASIC, ANY, X_OF_KIND, FLUSH, STRAIGHT, RED_FLAG, BLACK_SWAN}
enum CARD_RANK {ZERO,ACE,TWO,THREE, FOUR,FIVE,SIX,SEVEN,EIGHT,NINE,TEN,JACK,QUEEN,KING}
enum CARD_COLOR {RED,BLACK}

#Minimum number of cards, Base score, Combo mode
var combo_stats = {COMBO_TYPE.ANY : [],COMBO_TYPE.X_OF_KIND : [2, 20, COMBO_MODE.MULT], COMBO_TYPE.FLUSH : [3, 10, COMBO_MODE.ADD], COMBO_TYPE.STRAIGHT : [2, 20, COMBO_MODE.ADD]}

signal element_held
signal update_content_align(align_type)
signal changed_score(new_score)
signal draw_card
signal draw_shop

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
var card_rules = []

var play_speed = 1.5

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
var rules = []

var card_tooltip_pos = Vector2()
var is_card_tooltip_active = false
var card_tooltip_text = ""
var card_tooltip_title = ""

var current_effect_pitch = 1.
const NB_TRIGGER_MAX_PITCH = 20.

var combo_color = Color.html("#dd47ff")

func get_rank_name(rank):
	if rank <= 10 && rank != 1:
		return str(rank)
	else:
		return CARD_RANK.keys()[rank].to_lower()

func add_rule(type):
	rules.append(type)
	var c = CARD.instantiate()
	c.type = type
	c.scale = Vector2(0.065, 0.065)
	$"../game/CanvasLayer".add_child(c)
	card_rules.append(c)

func get_card_path(type, rank = 0, color = 0):
	match type:
		globals.CARD_TYPE.RED_FLAG:
			return "res://sprites/cards/red_flag.png"
		globals.CARD_TYPE.BLACK_SWAN:
			return "res://sprites/cards/black_swan.png"
		globals.CARD_TYPE.X_OF_KIND:
			return "res://sprites/cards/same.png"
		globals.CARD_TYPE.FLUSH:
			return "res://sprites/cards/color.png"
		globals.CARD_TYPE.STRAIGHT:
			return "res://sprites/cards/straight.png"
		globals.CARD_TYPE.ANY:
			return "res://sprites/cards/any.png"
		_:
			return "res://sprites/cards/%s_%s.png" % [str(rank), str(globals.CARD_COLOR.keys()[color]).to_lower()]

func get_combo_text(text):
	return "[color=%s]" % combo_color.to_html() + text + "[/color]"

func get_rule_desc(type):
	var base = "none"
	match type:
		CARD_TYPE.X_OF_KIND:
			base = "activates the " + get_combo_text("x of a kind combo") +  " (play cards with same rank)"
		CARD_TYPE.ANY:
			base = "activates the " + get_combo_text("any combo") +  " (score its value)"
		CARD_TYPE.STRAIGHT:
			base = "activates the " + get_combo_text("straight combo") +  " (play cards with increasing rank)"
		CARD_TYPE.FLUSH:
			base = "activates the " + get_combo_text("flush combo") +  " (play cards with same color)"
		CARD_TYPE.RED_FLAG:
			base = "+20 if red card"
		CARD_TYPE.BLACK_SWAN:
			base = "1 in 5 chance for x5 if black card"
	#return "[font_size=150][outline_color=#000][outline_size=30][color=#787878]rule[/color][/outline_size][/outline_color][/font_size]" + " : " + base
	return "[u]RULE[/u] : " + base

func get_card_color_string(color):
	match color:
		CARD_COLOR.RED:
			return "hearts"
	return "spades"

func get_card_descr(card):
	return ("" if card.color else "[color=#e60000]") + get_rank_name(card.rank) + " of " + get_card_color_string(card.color) + ("" if card.color else "[/color]") + "\n[font_size=100]" + get_rule_desc(card.type)


func get_card_title(type):
	match type:
		CARD_TYPE.BASIC:
			return ""
		CARD_TYPE.ANY:
			return get_combo_text("any") + " card"
		CARD_TYPE.STRAIGHT:
			return get_combo_text("straight") + " card"
		CARD_TYPE.X_OF_KIND:
			return get_combo_text("X of a kind") + " card"
		CARD_TYPE.FLUSH:
			return get_combo_text("flush") + " card"
		_:
			return CARD_TYPE.keys()[type].to_lower().replace("_", " ")


func launch_effect(card, bonus, op, rule_id, is_combo=false, name = ""):
	var effect = SCORE_EFFECT.instantiate()
	$"../game/CanvasLayer".add_child(effect)
	effect.position = card.global_position + Vector2(0,-150)
	if name == "":
		name = get_card_title(card.type)
	effect.launch(bonus, op, name, is_combo)
	card_rules[rule_id].play_card_tween()
	audio_manager.play_sound(audio_manager.SOUNDS.SCORE, current_effect_pitch)
	current_effect_pitch += (audio_manager.MAX_PITCH - 1.) / NB_TRIGGER_MAX_PITCH
	await card.play_card_tween().finished
	
func compute_combo(triggered_cards, combo, rule_id):
	var card = triggered_cards[0]
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
	if bonus > 0 || combo == COMBO_TYPE.ANY:
		score += bonus
		var name = "none"
		match combo:
			COMBO_TYPE.ANY:
				name = "any " + get_rank_name(card.rank)
			COMBO_TYPE.X_OF_KIND:
				name = str(count) + " of a kind"
			_:
				name = COMBO_TYPE.keys()[combo].to_lower() + " " + str(count)
		await launch_effect(card,bonus, "+", rule_id, true, name)
			
func compute_score():
	current_effect_pitch = 1.
	current_scoring_card_id = 0
	var triggered_cards = []
	while current_scoring_card_id < len(played_cards):
		var card = played_cards[current_scoring_card_id]
		triggered_cards.push_front(card)
		card.trigger()
		for i in range(len(rules)):
			var card_type = rules[i]
			match card_type:
				CARD_TYPE.ANY:
					await compute_combo(triggered_cards, COMBO_TYPE.ANY, i)
				CARD_TYPE.X_OF_KIND:
					await compute_combo(triggered_cards, COMBO_TYPE.X_OF_KIND, i)
				CARD_TYPE.FLUSH:
					await compute_combo(triggered_cards, COMBO_TYPE.FLUSH, i)
				CARD_TYPE.STRAIGHT:
					await compute_combo(triggered_cards, COMBO_TYPE.STRAIGHT, i)
				CARD_TYPE.RED_FLAG:
					if card.color == CARD_COLOR.RED:
						score += 20
						await launch_effect(card,20, "+", i)
				CARD_TYPE.BLACK_SWAN:
					if card.color == CARD_COLOR.BLACK && randi() % 5 == 0:
						score *= 5
						await launch_effect(card,5, "x", i)
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
				#e.init_attributes(r, c)
				e.sample_randomly()
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
