shader_type canvas_item;

const vec4 tint = vec4(0.75, 0.75, 0., 1.);
const float band_width = 0.25;

float w() {
	return sin(TIME/3.);
}

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	//if (abs(UV.x - w()) <= band_width && abs(UV.y - w()) <= band_width) {
	if (abs(UV.x - (UV.y - w())) <= band_width) {
		COLOR = vec4(1., 1., 1., rgba.a);
	} else {
		COLOR = rgba * tint;
	}
	//COLOR = rgba * tint * vec4(w(), w(), w(), 1.);
}