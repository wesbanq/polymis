shader_type canvas_item;

uniform vec4 tint;
uniform vec2 direction;
uniform vec2 offset;
uniform float speed;
uniform vec2 scale;
uniform float saved_time = 0.;

void fragment() {
	vec4 rgba = texture(TEXTURE, (offset + UV + direction * (saved_time > 0. ? saved_time : TIME) * speed) * scale);
	COLOR = vec4(tint.r, tint.g, tint.b, rgba.a * tint.a);
}
