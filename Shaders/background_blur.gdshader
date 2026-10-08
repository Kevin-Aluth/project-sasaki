shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 blur = texture(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
	blur.rgb *= 0.5;
	COLOR = blur;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
