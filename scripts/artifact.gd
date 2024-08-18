extends Node2D


enum ARTIFACT_TYPE {NONE, ADDER, MULTIPLIER, SPAWN_WISP}

@export var type = ARTIFACT_TYPE.NONE
var text = "Card"

@onready var label = $label_parent/Label
@onready var draggable = $draggable
@onready var color_rect = $draggable/ColorRect
@onready var sprite_2d = $Sprite2D
@onready var price_label = $price_label

const drag_type = globals.DRAG_TYPE.ARTIFACT

var price = 5


func trigger_artifact(s):
	var ns
	match type:
		ARTIFACT_TYPE.ADDER:
			ns = s + 10
		ARTIFACT_TYPE.MULTIPLIER:
			ns = s * 2
		_:
			ns = s
	return ns


func get_artifact_name():
	match type:
		ARTIFACT_TYPE.ADDER:
			return "+10"
		ARTIFACT_TYPE.MULTIPLIER:
			return "x2"
		#ARTIFACT_TYPE.SPAWN_WISP:
			#return "Summon a " + 
		_:
			return "None"

#func get_artifact_description():
	#match type:
		#ARTIFACT_TYPE.ADDER:
			#return "Add 10"
		#ARTIFACT_TYPE.MULTIPLIER:
			#return "Multiply by 2"
		#_:
			#return "Do nothing..."

func _process(delta):
	label.visible = !draggable.is_paid
	price_label.visible = draggable.is_paid
	price_label.text = str(price) + " G"

func _ready():
	label.text = get_artifact_name()
	color_rect.tooltip_text = get_artifact_name()

func sample_randomly():
	type = ARTIFACT_TYPE.values()[ randi() % (ARTIFACT_TYPE.size() - 1) + 1 ]

func trigger_artifact_tween():
	var tween = get_tree().create_tween()
	#tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite_2d, "scale", sprite_2d.scale*2, 0.1).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(sprite_2d, "scale", sprite_2d.scale, 0.1).set_trans(Tween.TRANS_EXPO)
	return tween
