shader_type canvas_item;

uniform vec4 tint;
uniform vec2 direction;
uniform vec2 offset;
uniform float speed;
uniform vec2 scale;

void fragment() {
	vec4 rgba = texture(TEXTURE, (offset + UV + direction * TIME * speed) * scale);
	COLOR = vec4(tint.r, tint.g, tint.b, rgba.a * tint.a);
}
