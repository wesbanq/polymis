shader_type canvas_item;

const vec4 tint = vec4(1., 1., 1., 0.25);
const float band_width = 0.3;
uniform bool override = false;

float w() {
	return sin(TIME/5.);
}

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	if (override) {
		COLOR = vec4(tint.r, tint.g, tint.b, rgba.a);
	} else {
		if (abs(UV.x - (UV.y - w())) <= band_width) {
			COLOR = vec4(1., 1., 1., rgba.a);
		} else {
			COLOR = vec4(rgba.r * tint.r, rgba.g * tint.g, rgba.b * tint.b, rgba.a);
		}
	}
}