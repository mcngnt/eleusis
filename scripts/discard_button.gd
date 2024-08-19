extends Button

var none_tex : Texture

var element_hovers = false


func _ready():
	#add_theme_stylebox_override("hover", get_theme_stylebox("normal"))
	##add_theme_stylebox_override("pressed", get_theme_stylebox("normal"))
	add_theme_stylebox_override("disabled", get_theme_stylebox("normal"))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	none_tex = get_theme_stylebox("hover").texture
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var s = get_theme_stylebox("hover")
	if len(globals.discard_deck) > 0:
		s.texture = globals.discard_deck[-1].sprite_2d.texture
	else:
		s.texture = none_tex
	add_theme_stylebox_override("normal", s)
	add_theme_stylebox_override("pressed", s)
	
	element_hovers = is_hovered() && globals.is_element_held
	

func _input(event):
	if event.is_action("drag") && event.is_released() && element_hovers:
		globals.is_element_held = false
		globals.discard_deck.append(globals.held_element)
		globals.held_cards.erase(globals.held_element)
		globals.update_content_align.emit(globals.ALIGN_TYPE.HELD_CARDS)
		$"../../../..".remove_child(globals.held_element)
		globals.held_element = null
		audio_manager.play_sound(audio_manager.SOUNDS.DISCARD)
		
		
		
	
