shader_type canvas_item;
uniform sampler2D noise_texture: repeat_enable;
uniform sampler2D noise_texture2: repeat_enable;
uniform float edge_fade_out;
uniform float edge_fade_in;
uniform float emission = 1.0;
uniform float time_scale = 1.0;
uniform vec3 light_color: source_color;
uniform vec3 dark_color: source_color;


float soft_light(float base, float blend){
	float limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float noise = texture(noise_texture, vec2(UV.x, UV.y + TIME * time_scale)).r;
	float noise2 = texture(noise_texture2, vec2(UV.x, UV.y + TIME * time_scale / 10.0)).r;
	float flames = soft_light(noise, noise2);
	flames = soft_light(smoothstep(edge_fade_out, edge_fade_in, UV.y), flames);
	vec3 col = mix(dark_color, light_color, flames);
	float mask = texture(TEXTURE, UV).r;
	col = mix(col, vec3(1.0), smoothstep(0.6, 1.1, UV.y));
	COLOR.rgb = col * emission;
	COLOR.a = mask;
	


}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
