extends Button

@export var disable_on_score_computing = false

@export var label : Label

enum {NORMAL,HOVERED, PRESSED}

var mode = NORMAL

func _ready():
	self.button_down.connect(_on_button_down)
	self.button_up.connect(_on_button_up)
	add_theme_stylebox_override("hover", get_theme_stylebox("normal"))
	#add_theme_stylebox_override("pressed", get_theme_stylebox("normal"))
	#add_theme_stylebox_override("disabled", get_theme_stylebox("normal"))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
func _on_button_up():
	audio_manager.play_sound(audio_manager.SOUNDS.INCOMING_COIN, 1., 5)
	mode = HOVERED

func _on_button_down():
	mode = PRESSED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_hovered():
		mode = NORMAL
	else:
		if mode != PRESSED:
			mode = HOVERED
	
	if label != null:
		label.visible = true
	
	match mode:
		NORMAL:
			add_theme_stylebox_override("normal", get_theme_stylebox("hover"))
		HOVERED:
			add_theme_stylebox_override("normal", get_theme_stylebox("hover"))
		PRESSED:
			if label != null:
				label.visible = false
			add_theme_stylebox_override("normal", get_theme_stylebox("pressed"))
	
	if label != null && disabled:
		label.visible = false
			
	
	#var value = 1.0
	#match mode:
		#NORMAL:
			#value = 1.0
		#HOVERED:
			#value = 0.8
		#PRESSED:
			#value  = 0.6
	#material.set_shader_parameter("source_modulate", Vector4(value,value,value,1.0))
	
	if disable_on_score_computing && globals.is_computing_score:
		disabled = true
