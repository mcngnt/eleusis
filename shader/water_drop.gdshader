shader_type canvas_item;

uniform vec4 water_color : source_color;
uniform vec4 outline_color : source_color;

uniform vec2 positions[300];
uniform float scales[300];
uniform int nb_drop;

const float ball_infl = 0.00015;
const float threshold = 0.685;

mat2 rot_mat(float angle)
{
	angle *= PI / 180.0;
    float sine = sin(angle), cosine = cos(angle);
    return mat2(vec2(cosine,-sine),vec2(sine,cosine));
}

void fragment() {
	float infl = 0.;
	vec2 i_resolution = 1.0 / SCREEN_PIXEL_SIZE ;
	vec2 i_resolution_normalized = i_resolution / max(i_resolution.x, i_resolution.y);
	vec2 pos = UV * i_resolution / max(i_resolution.x, i_resolution.y);
	//pos.x *= i_resolution.x;
	for(int i=0;i < nb_drop; i++)
	{
		vec2 true_position = positions[i] * i_resolution_normalized;
		float dist = length(pos - true_position);
		float current_infl = ball_infl;
		current_infl /= (pow(abs(pos.x - true_position.x)*1.,2.) + pow(abs(pos.y - true_position.y)*1.,2.0));
		infl += current_infl * scales[i]; 
	}
	if(infl > threshold)
	{
		COLOR = outline_color;
	}
	if(infl > threshold * 1.2)
	{
		COLOR = water_color;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
