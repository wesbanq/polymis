shader_type canvas_item;

uniform vec4 tint;

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	COLOR = vec4(rgba.r * tint.r, rgba.g * tint.g, rgba.b * tint.b, tint.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
