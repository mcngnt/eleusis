shader_type canvas_item;
render_mode blend_mix;

uniform vec2 offset = vec2(8.0, 8.0);
uniform vec4 modulate : source_color;
uniform vec4 source_modulate : source_color;
uniform float scale;

uniform float radius;

uniform bool only_shadow;

uniform bool use_dissolve;

uniform sampler2D dissolve_texture : source_color;
uniform float dissolve_value : hint_range(0,1);
uniform float burn_size: hint_range(0.0, 1.0, 0.01);
uniform vec4 burn_color: source_color;

float dissolve(vec2 uv){
    vec4 noise_texture = texture(dissolve_texture, uv);

	float burn_size_step = burn_size * step(0.001, dissolve_value) * step(dissolve_value, 0.999);
	float threshold = smoothstep(noise_texture.x-burn_size_step, noise_texture.x, dissolve_value);
	//float border = smoothstep(noise_texture.x, noise_texture.x + burn_size_step, dissolve_value);

	//COLOR.a *= threshold;
	//COLOR.rgb = mix(burn_color.rgb, main_texture.rgb, border);
	return threshold;
}

vec4 sample(sampler2D tex,vec2 uv)
{
	if(use_dissolve)
	{
		return texture(tex, uv) * dissolve(uv);
	}
	return texture(tex, uv);
}


vec4 blur(sampler2D tex,vec2 ps,vec2 uv_pos) {
	vec4 col = sample(tex, uv_pos);

	col += sample(tex, uv_pos + vec2(0.0, -radius) * ps);
	col += sample(tex, uv_pos + vec2(0.0, radius) * ps);
	col += sample(tex, uv_pos + vec2(-radius, 0.0) * ps);
	col += sample(tex, uv_pos + vec2(radius, 0.0) * ps);
	col /= 5.0;

	return col;
}

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;

	//vec4 shadow = vec4(modulate.rgb, blur(TEXTURE,ps, (UV - offset * ps)/scale).a * modulate.a);
	vec4 shadow = vec4(modulate.rgb, blur(TEXTURE,ps, (UV - offset * ps)/scale).a * modulate.a);
	if(only_shadow)
	{
		COLOR = shadow;
	}
	else
	{
		vec4 col = sample(TEXTURE, UV) * source_modulate;
		COLOR = mix(shadow, col, col.a);
	}
}