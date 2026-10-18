shader_type canvas_item;

uniform float magnification: hint_range(1.0, 2.0, 0.1) = 2.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec2 center = vec2(0.5);


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv = UV;
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 aspect_uv = UV;
	aspect_uv *= resolution.x / resolution.y;
	uv += magnification * (center - uv);
	COLOR = texture(SCREEN_TEXTURE, uv);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
