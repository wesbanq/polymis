shader_type canvas_item;

uniform vec3 tint = vec3(1.0, 1.0, 1.0);
uniform vec3 otint = vec3(0.3, 0.3, 0.3);
uniform bool active = true;

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	if (active) {
		COLOR = vec4(rgba.r * tint.r, rgba.g * tint.g, rgba.b * tint.b, rgba.a);
	} else {
		COLOR = vec4(rgba.r * otint.r, rgba.g * otint.g, rgba.b * otint.b, rgba.a);
	}
}