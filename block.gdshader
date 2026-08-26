shader_type canvas_item;

uniform vec4 tint;
uniform bool override = false;

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	if (override) {
		COLOR = vec4(tint.r, tint.g, tint.b, rgba.a);
	} else {
		COLOR = vec4(rgba.r * tint.r, rgba.g * tint.g, rgba.b * tint.b, rgba.a);
	}
}
