@tool
extends RichTextEffect
class_name RichTextGradient

# Syntax: [matrix clean=2.0 dirty=1.0 span=50][/matrix]

# Define the tag name.
var bbcode = "gradient"


func _process_custom_fx(char_fx):
	# Get parameters, or use the provided default value if missing.
	var speed = char_fx.env.get("freq", 5.0)
	var span = char_fx.env.get("span", 10.0)
	var color1 = char_fx.env.get("color1", Color.html("#e74e53"))
	var color2 = char_fx.env.get("color2", Color.html("#f5cc20"))
	
	#if type_string(typeof(color1)) == "String":
		#color1 = Color.html(color1)
		#color2 = Color.html(color2)
	#var alpha = sin(char_fx.elapsed_time * speed + (char_fx.range.x / span)) * 0.5 + 0.5
	#char_fx.color.a = alpha
	
	var t = sin(char_fx.elapsed_time * speed + (char_fx.range.x / span)) * 0.5 + 0.5
	char_fx.color = lerp(color1, color2, t)
	
	return true
