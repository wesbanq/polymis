shader_type canvas_item;

const vec4 tint = vec4(1., 0., 1., 1.);

float w(float x, float y) {
	return cos(TIME) + sin(x * y);
}

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	COLOR = rgba * w(UV.x, UV.y) * tint;
}