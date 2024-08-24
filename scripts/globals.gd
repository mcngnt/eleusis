extends Node

enum DRAG_TYPE {NONE, CARD, ARTIFACT}
enum ALIGN_TYPE {NONE, ARTIFACTS, HELD_CARDS, SHOP, FULL_DECK, PLAYED_CARDS, DISCARD_DECK, CARD_RULES, DELETE_CARDS}
enum COMBO_TYPE {ANY, X_OF_KIND, FLUSH, STRAIGHT, FIBONACCI}
enum COMBO_MODE {ADD, MULT}

enum CARD_TYPE {NONE, BASIC, ANY, X_OF_KIND, FLUSH, STRAIGHT, RED_FLAG, BLACK_SWAN, PAR, CRESUS, TALKING_HEAD, PAREIDOLIA, FIBONACCI, GOLDEN_TICKET, UNITY, ARMY, ETERNAL_RETURN, GROWTH_HORMONE, DOLLY, BLANK_CARD, ENCODING, BOULDER,PAY_TO_WIN, INUMERATE, THE_RIPPER, POLYCEPHALY}
enum CARD_RANK {ZERO,ACE,TWO,THREE, FOUR,FIVE,SIX,SEVEN,EIGHT,NINE,TEN,JACK,QUEEN,KING}
enum CARD_COLOR {RED,BLACK}

#Minimum number of cards, Base score, Combo mode
var combo_stats = {COMBO_TYPE.ANY : [],COMBO_TYPE.X_OF_KIND : [2, 20, COMBO_MODE.MULT], COMBO_TYPE.FLUSH : [3, 10, COMBO_MODE.ADD], COMBO_TYPE.STRAIGHT : [2, 20, COMBO_MODE.ADD], COMBO_TYPE.FIBONACCI : [3,100, COMBO_MODE.MULT]}

signal element_held
signal update_content_align(align_type)
signal changed_score(new_score)
signal draw_card
signal draw_shop

signal create_droplet(pos, delay)
signal move_droplet(target_pos, delay)

signal instanciate_card(c)
signal delete_card(c)

signal score_tween
signal change_money(amount, obj)

const CARD = preload("res://scenes/card.tscn")
const SCORE_EFFECT = preload("res://scenes/score_effect.tscn")

var score : float = 0.
var score_mantissa : int = 0

var money = 0

var held_cards = []
var shop = []
var full_deck = []
var played_cards = []
var discard_deck = []
var card_rules = []
var delete_cards = []

var play_speed = 1.
var user_play_speed = 1.5

var showing_deck = false
var showing_discard = false

var held_element = null
var is_element_held = false


var start_held_card_nb = 7
var start_nb_draws = 4
var max_nb_tape = 7

var level_id = 0
var nb_draw_left

var is_computing_score = false

var current_element_hovered = null
var current_scoring_card_id = 0
var current_rule_card_id = 0
var rules = []
var starting_rules = [CARD_TYPE.ANY, CARD_TYPE.FLUSH, CARD_TYPE.X_OF_KIND, CARD_TYPE.STRAIGHT]

var card_tooltip_pos = Vector2()
var is_card_tooltip_active = false
var card_tooltip_text = ""
var card_tooltip_title = ""

var current_effect_pitch = 1.
const NB_TRIGGER_MAX_PITCH = 20.

var combo_color = Color.html("#dd47ff")

var nb_activation = 0


func score_add(bonus):
	score += bonus
	score_tween.emit()

func score_mult(bonus):
	score *= bonus
	score_tween.emit()

func is_rank_equal(card, rank):
	if card.is_rank_joker:
		return true
	return card.rank == rank

func is_rank_greater(card, rank):
	if card.is_rank_joker:
		return true
	return card.rank <= rank

func get_rank_name(card):
	if card.is_rank_joker:
		return "JOKER"
	if card.rank <= 10 && card.rank != 1:
		return str(card.rank)
	else:
		return CARD_RANK.keys()[card.rank].to_lower()

func add_rule(type, base_card = null):
	rules.append(type)
	var c = CARD.instantiate()
	c.type = type
	c.scale = Vector2(0.065, 0.065)
	c.position = Vector2(750, -100)
	$"../game/CanvasLayer".add_child(c)
	card_rules.append(c)
	if base_card != null:
		c.position = base_card.position

func get_card_path(type, rank = 0, color = 0):
	match type:
		globals.CARD_TYPE.X_OF_KIND:
			return "res://sprites/cards/same.png"
		globals.CARD_TYPE.FLUSH:
			return "res://sprites/cards/color.png"
		globals.CARD_TYPE.BASIC:
			return "res://sprites/cards/%s_%s.png" % [str(rank), str(globals.CARD_COLOR.keys()[color]).to_lower()]
		#_:
			#return "res://sprites/cards/none.png"
		_:
			return "res://sprites/cards/" + CARD_TYPE.keys()[type].to_lower() + ".png"



func get_combo_text(text):
	return "[color=%s]" % combo_color.to_html() + text + "[/color]"

func get_rule_desc(type):
	var base = "none"
	var is_rule = true
	match type:
		CARD_TYPE.X_OF_KIND:
			base = "activates the " + get_combo_text("x of a kind combo") +  " (cards with same rank)"
		CARD_TYPE.ANY:
			base = "activates the " + get_combo_text("any combo") +  " (score card's value)"
		CARD_TYPE.STRAIGHT:
			base = "activates the " + get_combo_text("straight combo") +  " (cards with increasing rank)"
		CARD_TYPE.FLUSH:
			base = "activates the " + get_combo_text("flush combo") +  " (cards with same color)"
		CARD_TYPE.RED_FLAG:
			base = "+20 if red card"
		CARD_TYPE.BLACK_SWAN:
			base = "1 in 5 chance for x5 if black card"
		CARD_TYPE.PAR:
			base = "x2 if card's rank is below 4 (or ace)"
		CARD_TYPE.TALKING_HEAD:
			base = "x2 if head"
		CARD_TYPE.CRESUS:
			base = "add money to score if 7"
		CARD_TYPE.PAREIDOLIA:
			base = "every card is considered as head"
		CARD_TYPE.FIBONACCI:
			base = "activates the " + get_combo_text("fibonacci combo") +  " (cards following the fibonacci sequence)"
		CARD_TYPE.GOLDEN_TICKET:
			base = "gain 50 coins"
			is_rule = false
		CARD_TYPE.UNITY:
			base = "retriggers if ace"
		CARD_TYPE.ARMY:
			base = "x1.5 for every card that is a digit in hand if 8"
		CARD_TYPE.ETERNAL_RETURN:
			base = "if 0 in hand, restart the tape"
		CARD_TYPE.GROWTH_HORMONE:
			base = "+1 tape size"
			is_rule = false
		CARD_TYPE.DOLLY:
			base = "add 2 copies of this card in hand"
			is_rule = false
		CARD_TYPE.BLANK_CARD:
			return "[u]INFO[/u] : joker can be any rank"
		CARD_TYPE.ENCODING:
			base =  "every card is considered as a digit"
		CARD_TYPE.BOULDER:
			base =  "+100 if 3"
		CARD_TYPE.PAY_TO_WIN:
			base =  "retrigger every digit, pay 5 coins per trigger"
		CARD_TYPE.INUMERATE:
			base = "1 in 5 chance to retrigger at every trigger"
		CARD_TYPE.THE_RIPPER:
			base = "x4 if jack"
		CARD_TYPE.POLYCEPHALY:
			base = "retrigger if head"
	
	if base == "none":
		return ""
	return ("[u]RULE[/u] : " if is_rule  else "[u]ON TRIGGER[/u] : ") + base

func get_card_color_string(color):
	match color:
		CARD_COLOR.RED:
			return "hearts"
	return "spades"

func get_card_descr(card):
	return ("" if card.color else "[color=#e60000]") + get_rank_name(card) + " of " + get_card_color_string(card.color) + ("" if card.color else "[/color]") + "\n[font_size=100]" + get_rule_desc(card.type)


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
		CARD_TYPE.FIBONACCI:
			return get_combo_text("fibonacci") + " card"
		_:
			return CARD_TYPE.keys()[type].to_lower().replace("_", " ")


func launch_effect(card, bonus, op, rule_id, name = "", is_combo=false):
	nb_activation += 1
	var effect = SCORE_EFFECT.instantiate()
	$"../game/CanvasLayer".add_child(effect)
	effect.position = card.global_position + Vector2(0,-150)
	if name == "":
		name = get_card_title(rules[rule_id])
	effect.launch(bonus, op, name, is_combo)
	if rule_id >= 0:
		card_rules[rule_id].play_card_tween()
	audio_manager.play_sound(audio_manager.SOUNDS.SCORE, current_effect_pitch)
	current_effect_pitch += (audio_manager.MAX_PITCH - 1.) / NB_TRIGGER_MAX_PITCH
	if current_effect_pitch > audio_manager.MAX_PITCH:
		current_effect_pitch = lerp(1., float(audio_manager.MAX_PITCH), 0.7)
	play_speed += .1 * user_play_speed
	print(play_speed)
	await card.play_card_tween()
	
func compute_combo(triggered_cards, combo, rule_id):
	var card = triggered_cards[0]
	var bonus = 0
	var count = 0
	var last_card = card
	for i in range(len(triggered_cards)):
		var prev_card = triggered_cards[i]
		match combo:
			COMBO_TYPE.ANY:
				bonus = card.get_value()
				break
			COMBO_TYPE.X_OF_KIND:
				if prev_card != last_card && !is_rank_equal(prev_card, last_card.rank):
					break
			COMBO_TYPE.FLUSH:
				if prev_card != last_card && last_card.color != prev_card.color:
					break
			COMBO_TYPE.STRAIGHT:
				if prev_card != last_card && last_card.get_ordering() - 1 != prev_card.get_ordering():
					break
			COMBO_TYPE.FIBONACCI:
				if i >= 2 && !is_rank_equal(prev_card, triggered_cards[i-2].rank - triggered_cards[i-1].rank):
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
		score_add(bonus)
		var name = "none"
		match combo:
			COMBO_TYPE.ANY:
				name = "any " + get_rank_name(card)
			COMBO_TYPE.X_OF_KIND:
				name = str(count) + " of a kind"
			_:
				name = COMBO_TYPE.keys()[combo].to_lower() + " " + str(count)
		await launch_effect(card,bonus, "+", rule_id,name, true)

func is_card_head(card):
	return card.rank > 10 || CARD_TYPE.PAREIDOLIA in rules || card.is_rank_joker

func is_card_digit(card):
	return card.rank < 10 || CARD_TYPE.ENCODING in rules

func compute_score(nb_restart = 0):
	if nb_restart == 0:
		play_speed = user_play_speed
		nb_activation = 0
	current_effect_pitch = 1.
	current_scoring_card_id = 0
	current_rule_card_id = 0
	var current_nb_trigger = 0
	var retrigger_cards_id = []
	var triggered_cards = []
	while current_scoring_card_id < len(played_cards):
		var card = played_cards[current_scoring_card_id]
		if current_nb_trigger == 0:
			triggered_cards.push_front(card)
		
		await card.trigger(current_nb_trigger == 0 && nb_restart == 0, null)
			#await card.trigger(current_nb_trigger == 0 && nb_restart == 0, triggered_cards[1])
		#else:
			#await card.trigger(current_nb_trigger == 0 && nb_restart == 0, null)
			
		for i in range(len(rules)):
			current_rule_card_id = i
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
				CARD_TYPE.FIBONACCI:
					await compute_combo(triggered_cards, COMBO_TYPE.FIBONACCI, i)
				CARD_TYPE.RED_FLAG:
					if card.color == CARD_COLOR.RED:
						score_add(20)
						await launch_effect(card,20, "+", i)
				CARD_TYPE.BLACK_SWAN:
					if card.color == CARD_COLOR.BLACK && randi() % 5 == 0:
						score_mult(5)
						await launch_effect(card,5, "x", i)
				CARD_TYPE.PAR:
					if is_rank_greater(card,4):
						score_mult(2)
						await launch_effect(card,2, "x", i)
				CARD_TYPE.TALKING_HEAD:
					if is_card_head(card):
						score_mult(2)
						await launch_effect(card,2, "x", i)
				CARD_TYPE.CRESUS:
					if is_rank_equal(card,7):
						score_add(money)
						await launch_effect(card,money, "+", i)
				CARD_TYPE.BOULDER:
					if is_rank_equal(card,3):
						score_add(100)
						await launch_effect(card,100, "+", i)
				CARD_TYPE.ARMY:
					if is_rank_equal(card,8):
						var old_play_speed = play_speed
						play_speed = old_play_speed * 2
						for held_card in held_cards:
							if is_card_digit(held_card):
								score_mult(1.5)
								held_card.play_card_tween()
								await launch_effect(card,1.5, "x", i)
						play_speed = old_play_speed
				CARD_TYPE.THE_RIPPER:
					if is_rank_equal(card, 11):
						score_mult(4)
						await launch_effect(card,4, "x", i)
					
		
		
		if current_nb_trigger == 0:
			retrigger_cards_id = []
			var nb_pay_to_win = 1
			for i in range(len(rules)):
				match rules[i]:
					CARD_TYPE.UNITY:
						if is_rank_equal(card,1):
							retrigger_cards_id.append(i)
					CARD_TYPE.PAY_TO_WIN:
						if is_card_digit(card) && globals.money >= 10 * nb_pay_to_win:
							nb_pay_to_win += 1
							retrigger_cards_id.append(i)
					CARD_TYPE.POLYCEPHALY:
						if is_card_head(card):
							retrigger_cards_id.append(i)
					_:
						pass
		
		for i in range(len(rules)):
			if rules[i] == CARD_TYPE.INUMERATE && randi() % 5 == 0:
				retrigger_cards_id.push_front(i)
				break
		
		current_nb_trigger += 1
		if len(retrigger_cards_id) == 0:
			current_scoring_card_id += 1
			current_nb_trigger = 0
		else:
			var card_trigger_id = retrigger_cards_id.pop_front()
			if rules[card_trigger_id] == CARD_TYPE.PAY_TO_WIN:
				change_money.emit(-10, card_rules[card_trigger_id])
			await launch_effect(card, 0, "a", card_trigger_id)
	
	var nb_restart_needed = 0
	var restarting_cards_id = []
	for i in range(len(rules)):
		match rules[i]:
			CARD_TYPE.ETERNAL_RETURN:
				var zero_in_hand = false
				for held_card in held_cards:
					if is_rank_equal(held_card,0):
						zero_in_hand = true
				if zero_in_hand:
					nb_restart_needed += 1
					restarting_cards_id.append(i)
			_:
				pass
	if nb_restart < nb_restart_needed:
		await launch_effect(played_cards[-1], 0, "r", restarting_cards_id[nb_restart])
		await compute_score(nb_restart + 1)


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
				while e.type in [CARD_TYPE.BASIC, CARD_TYPE.CRESUS, CARD_TYPE.X_OF_KIND, CARD_TYPE.FLUSH, CARD_TYPE.STRAIGHT, CARD_TYPE.RED_FLAG, CARD_TYPE.RED_FLAG, CARD_TYPE.ANY]:
					e.sample_randomly()
				el.append(e)
		#for i in range(10):
			#var e = CARD.instantiate()
			#e.sample_randomly(CARD_TYPE.values()[-1])
			#el.append(e)
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
