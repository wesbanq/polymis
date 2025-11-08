shader_type canvas_item;

float w() {
	return abs(sin(TIME*10.));
}

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	COLOR = rgba * w() * vec4(1., 0., 1., 1.);
}