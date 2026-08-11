shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 50.0) = 12;
uniform float core_width : hint_range(0.0, 1.0) = 1;
uniform float core_length : hint_range(0.0, 1.0) = 1;

void fragment() {
    float y_dist = abs(UV.y - 0.5);
    float x_dist = max(0.1, abs(UV.x - 0.5));

    float core_y_mask = 1.0 - smoothstep(0.0, core_width, y_dist);
    float core_x_mask = 1.0 - smoothstep(0.0, core_length, x_dist);
    float core_mask = core_y_mask * core_x_mask;
    vec4 core_color = COLOR * glow_intensity;
    core_color.a = core_mask;

    COLOR = core_color;
}