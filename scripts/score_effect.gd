extends Node2D

@onready var bonus_label = $bonus_label
@onready var rectangle = $Rectangle
@onready var circle = $Circle
@onready var effect_label = $effect_label

var plus_color = Color.html("#ff5959")
var x_color = Color.html("#ffc100")
var effect_color = Color.html("#47b9ff")
#var bonus_value = 0
#var operator = "+"
#var effect_name = "none"


# Called when the node enters the scene tree for the first time.
func _ready():
	bonus_label.visible = false
	effect_label.visible = false
	rectangle.visible = false
	circle.visible = false

func launch(bonus_value = 0, operator = "+", effect_name = "none", is_combo = false):
	bonus_label.text = operator + str(bonus_value)
	effect_label.text = effect_name
	
	if operator == "+":
		circle.material.set_shader_parameter("modulate", plus_color)
	else:
		circle.material.set_shader_parameter("modulate", x_color)
	
	if is_combo:
		rectangle.material.set_shader_parameter("modulate", globals.combo_color)
	else:
		rectangle.material.set_shader_parameter("modulate", effect_color)
	
	bonus_label.visible = true
	effect_label.visible = true
	rectangle.visible = true
	circle.visible = true
	var bonus_label_vec = bonus_label.scale
	var effect_label_vec = effect_label.scale
	var rectangle_vec = rectangle.scale
	var circle_vec = circle.scale
	bonus_label.scale = Vector2()
	effect_label.scale = Vector2()
	rectangle.scale = Vector2()
	circle.scale = Vector2()
	
	var start_delay = 0.35 / globals.play_speed
	var middle_delay = 0.3 / globals.play_speed
	var end_delay = 0.35 / globals.play_speed
	
	
	var tween = get_tree().create_tween()
	tween.tween_property(rectangle, "scale", rectangle_vec, start_delay).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(middle_delay)
	tween.tween_property(rectangle, "scale", Vector2(), end_delay).set_trans(Tween.TRANS_EXPO)
	
	rectangle.rotation = PI/2
	tween = get_tree().create_tween()
	tween.tween_property(rectangle, "rotation", 0, start_delay).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(middle_delay)
	tween.tween_property(rectangle, "rotation", -PI/2, end_delay).set_trans(Tween.TRANS_EXPO)
	
	tween = get_tree().create_tween()
	tween.tween_property(circle, "scale", circle_vec, start_delay).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(middle_delay)
	tween.tween_property(circle, "scale", Vector2(), end_delay).set_trans(Tween.TRANS_EXPO)
	
	circle.rotation = PI/2
	tween = get_tree().create_tween()
	tween.tween_property(circle, "rotation", 0,start_delay).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(middle_delay)
	tween.tween_property(circle, "rotation", -PI/2, end_delay).set_trans(Tween.TRANS_EXPO)
	
	tween = get_tree().create_tween()
	tween.tween_property(bonus_label, "scale", bonus_label_vec,start_delay).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(middle_delay)
	tween.tween_property(bonus_label, "scale", Vector2(), end_delay).set_trans(Tween.TRANS_EXPO)
	
	tween = get_tree().create_tween()
	tween.tween_property(effect_label, "scale", effect_label_vec, start_delay).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(middle_delay)
	tween.tween_property(effect_label, "scale", Vector2(), end_delay).set_trans(Tween.TRANS_EXPO)
	
	await get_tree().create_timer(start_delay + middle_delay + end_delay).timeout
	queue_free()
