extends Node2D

enum SOUNDS {ACCEPT, CARD, GET_COIN, INCOMING_COIN, SCORING, TRIGGER, SCORE}

const MAX_PITCH = 2.5

func _ready():
	for s in SOUNDS.values():
		var stream_player = AudioStreamPlayer2D.new()
		var path = "res://sounds//" + SOUNDS.keys()[s].to_lower() + ".wav"
		stream_player.stream = load(path)
		add_child(stream_player)

func play_sound(s, pitch=1):
	pitch = min(pitch, MAX_PITCH)
	get_child(s).pitch_scale = pitch
	get_child(s).play()