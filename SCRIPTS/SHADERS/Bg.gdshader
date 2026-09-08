
shader_type canvas_item;

// Color Palette Controls
uniform vec4 base_dark_blue : source_color = vec4(0.02, 0.04, 0.12, 1.0);
uniform vec4 cyan_glow : source_color = vec4(0.0, 0.4, 0.8, 1.0);
uniform vec4 deep_purple : source_color = vec4(0.08, 0.02, 0.2, 1.0);

// Animation Controls
uniform float speed : hint_range(0.1, 2.0) = 0.3;
uniform float scale : hint_range(1.0, 20.0) = 4.0;
uniform float wave_intensity : hint_range(0.1, 2.0) = 0.6;

// Pseudo-random helper function
vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// 2D Perlin Noise
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
		    dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
		    dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y
	);
}

// Fractional Brownian Motion (FBM) for smooth layered organic textures
float fbm(vec2 uv) {
	float val = 0.0;
	float amp = 0.5;
	vec2 shift = vec2(100.0);
	// Rotate matrix to reduce axis alignment artifacts
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));

	for (int i = 0; i < 4; i++) {
		val += amp * noise(uv);
		uv = rot * uv * 2.0 + shift;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	// Normalize coordinates and account for aspect ratio distortion
	vec2 uv = UV * scale;
	
	// Animate time factor
	float t = TIME * speed;

	// Distort coordinates dynamically (domain warping)
	vec2 q = vec2(
		fbm(uv + vec2(0.0, 0.0) + vec2(t * 0.2, t * 0.1)),
		fbm(uv + vec2(5.2, 1.3) + vec2(t * 0.1, t * 0.3))
	);

	vec2 r = vec2(
		fbm(uv + 4.0 * q + vec2(1.7 - t * 0.15, 9.2 + t * 0.1)),
		fbm(uv + 4.0 * q + vec2(8.3 + t * 0.1, 2.8 - t * 0.2))
	);

	float f = fbm(uv + 4.0 * r);

	// Base color blending
	vec4 final_color = mix(base_dark_blue, deep_purple, clamp(f * f * 4.0, 0.0, 1.0));

	// Add glowing highlights where waves warp closer together
	final_color = mix(final_color, cyan_glow, clamp(length(q) * wave_intensity, 0.0, 1.0));
	final_color = mix(final_color, vec4(0.2, 0.7, 1.0, 1.0), clamp(length(r.x) * 0.5, 0.0, 1.0));

	// Add soft radial vignette to keep center lit and edges subtle
	float dist_from_center = length(UV - vec2(0.5));
	final_color.rgb *= smoothstep(0.8, 0.2, dist_from_center * 0.8);

	COLOR = vec4(final_color.rgb, 1.0);
}