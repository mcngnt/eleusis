shader_type canvas_item;




const float SCALE = 10.0;
const int ML = 0;
uniform float AA_SCALE = 41.0;
uniform float LINE_THICKNESS = 0.366;


uniform vec4 modulate : source_color = vec4(1);


vec4 diag(vec4 sum, vec2 uv, vec2 p1, vec2 p2,vec4 base, sampler2D iChannel0)
{
    vec4 v1 = texelFetch(iChannel0,ivec2(uv+p1),ML);
    vec4 v2 = texelFetch(iChannel0,ivec2(uv+p2),ML);
	
	vec4 v = texelFetch(iChannel0,ivec2(uv+p1+p2),ML);
	
	vec4 negv1 = texelFetch(iChannel0,ivec2(uv-p1),ML);
    vec4 negv2 = texelFetch(iChannel0,ivec2(uv-p2),ML);
	
	vec4 otherv = texelFetch(iChannel0,ivec2(uv+p1-p2),ML);
	vec4 negotherv = texelFetch(iChannel0,ivec2(uv-p1+p2),ML);

	bool diag = v1 != v && v2 != v && v == base && (negv1 != v || negv2 != v) && otherv != v && negotherv != v;

    if (v1 == v2 && !diag)
	{
    	vec2 dir = p2-p1;
        vec2 lp = uv-(floor(uv+p1)+.5);
    	dir = normalize(vec2(dir.y,-dir.x));
        float l = clamp((LINE_THICKNESS-dot(lp,dir))*AA_SCALE,0.,1.);
        sum = mix(sum,v1,l);
    }

    return sum;
}


void fragment()
{
	vec2 ip = UV;
	ip = UV * (1.0 / TEXTURE_PIXEL_SIZE);
	

		vec4 s = texelFetch(TEXTURE,ivec2(ip),ML);
		vec4 base = s;
		

		s = diag(s,ip,vec2(-1,0),vec2(0,1),base, TEXTURE);
		s = diag(s,ip,vec2(0,1),vec2(1,0),base, TEXTURE);
		s = diag(s,ip,vec2(1,0),vec2(0,-1),base, TEXTURE);
		s = diag(s,ip,vec2(0,-1),vec2(-1,0),base, TEXTURE);


		COLOR = s * modulate;
}