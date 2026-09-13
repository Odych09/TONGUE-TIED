shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float diamond_size = 32.0;

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	float x_fraction = fract(FRAGCOORD.x / diamond_size);
	float y_fraction = fract(FRAGCOORD.y / diamond_size);
	
	float distance_from_center = abs(x_fraction - 0.5) + abs(y_fraction - 0.5);
	
	if (distance_from_center > progress * 2.0) {
		discard;
	}
	
	COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}