shader_type canvas_item;

uniform bool avail = true;
uniform vec4 tint = vec4(.8, 0.0, 0.0, 1.0);
uniform float progress = 0.0;

const float ua_mult = 0.4;
const float a_mult = 0.7;

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	if (avail) {
		if (UV.x <= progress) {
			COLOR = vec4(rgba.r * tint.r, rgba.g * tint.g, rgba.b * tint.b, rgba.a);
		} else {
			COLOR = vec4(rgba.r * tint.r * a_mult, rgba.g * tint.g * a_mult, rgba.b * tint.b * a_mult, rgba.a);
		}
	} else {
		COLOR = vec4(rgba.r * tint.r * ua_mult, rgba.g * tint.g * ua_mult, rgba.b * tint.b * ua_mult, rgba.a);
	}
}
