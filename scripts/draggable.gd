extends Area2D



@onready var parent = get_parent()

var dragging = false
var mouse_hovered = false
var target_position

var align_zone = null



@export var drag_type = globals.DRAG_TYPE.NONE
@export var handle_tooltip = false
@export var can_be_played = false

var is_frozen = false
var is_paid = false

var starting_align_zone = null
var starting_pos = Vector2()

var number = 0


func _ready():
	target_position = parent.position
	if align_zone != null:
		align_zone.try_add_element(parent)


func sound_buying():
	var amount = 4
	for i in range(4):
		audio_manager.play_sound(audio_manager.SOUNDS.INCOMING_COIN, float(i)/float(amount) * audio_manager.MAX_PITCH)
		await get_tree().create_timer(.02 / globals.play_speed).timeout

func _input(event):
	if is_paid && mouse_hovered && event.is_action("drag") && event.is_released():
		if parent.price <= globals.money:
			globals.money -= parent.price
			sound_buying()
			is_frozen = false
			is_paid = false
			align_zone.erase_element(parent)
			align_zone = null
			match parent.drag_type:
				globals.DRAG_TYPE.CARD:
					globals.held_cards.append(parent)
					globals.update_content_align.emit(globals.ALIGN_TYPE.HELD_CARDS)
				_:
					pass
	if is_frozen:
		return
	if event.is_action("drag"):
		if event.is_pressed() && mouse_hovered && !globals.is_element_held:
			dragging = true
			parent.z_index = 1000
			globals.held_element = parent
			globals.is_element_held = true
			globals.element_held.emit()
			starting_align_zone = align_zone
			starting_pos = target_position
		else:
			if globals.held_element == parent:
				target_position = parent.position
				globals.is_element_held = false
				if align_zone != null:
					align_zone.try_add_element(parent)
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		parent.position = event.position
	if handle_tooltip:
		$ColorRect.visible = !dragging



func _on_mouse_entered():
	mouse_hovered = true

func _on_mouse_exited():
	mouse_hovered = false

func _process(delta):
	if mouse_hovered && (globals.current_element_hovered == null || abs(globals.current_element_hovered.global_position.x - 40 - get_viewport().get_mouse_position().x) > abs(global_position.x - get_viewport().get_mouse_position().x)):
		globals.current_element_hovered = self
	
	if !dragging:
		parent.position = (target_position + parent.position)/2.0
		if mouse_hovered && self == globals.current_element_hovered:
			parent.position = (target_position + Vector2(0,-20) + parent.position)/2.0
		else:
			parent.position = (target_position + Vector2(0,sin(Time.get_ticks_msec() * 0.002 + number * 1.) * 5) + parent.position)/2.0
	else:
		target_position = position
	
	
