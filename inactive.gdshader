shader_type canvas_item;

uniform bool avail = true;
uniform vec4 tint = vec4(1., 1., 1., 1.);
const float ua_mult = 0.25;

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	if (avail) {
		COLOR = vec4(rgba.r * tint.r, rgba.g * tint.g, rgba.b * tint.b, rgba.a);
	} else {
		COLOR = vec4(rgba.r * tint.r * ua_mult, rgba.g * tint.g * ua_mult, rgba.b * tint.b * ua_mult, rgba.a);
	}
}
