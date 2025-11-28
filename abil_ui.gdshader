shader_type canvas_item;

uniform vec4 tint = vec4(0.8, 0.8, 0.0, 1.0);
uniform vec4 otint = vec4(0.3, 0.3, 0.3, 1.0);
uniform float progress = 0;

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	if (UV.y <= (1.-progress)) {
		COLOR = vec4(rgba.r * otint.r, rgba.g * otint.g, rgba.b * otint.b, rgba.a);
	} else {
		COLOR = vec4(rgba.r * tint.r, rgba.g * tint.g, rgba.b * tint.b, rgba.a);
	}
}
