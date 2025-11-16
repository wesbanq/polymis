shader_type canvas_item;

uniform bool active = true;
uniform vec3 tint = vec3(1., 1., 1.);
uniform vec3 itint = vec3(.5, .5, .5);

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	if (active) {
		COLOR = vec4(rgba.r * tint.r, rgba.g * tint.g, rgba.b * tint.b, rgba.a);
	} else {
		COLOR = vec4(rgba.r * itint.r, rgba.g * itint.g, rgba.b * itint.b, rgba.a);
	}
}
