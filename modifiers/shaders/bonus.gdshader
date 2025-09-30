shader_type canvas_item;

uniform vec4 tint;
uniform vec3 et;

float w() {
	return abs(sin(TIME));
}

void fragment() {
	vec4 rgba = texture(TEXTURE, UV);
	COLOR = vec4(tint.r * w() + et.r * (1.0-w()), tint.g * w() + et.g * (1.0-w()), tint.b * w() + et.b * (1.0-w()), tint.a);
}