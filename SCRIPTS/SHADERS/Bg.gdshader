shader_type canvas_item;

// Bright, vibrant, cute tropical lagoon palette
uniform vec4 water_deep : source_color = vec4(0.01, 0.42, 0.48, 1.0);
uniform vec4 water_mid : source_color = vec4(0.04, 0.68, 0.68, 1.0);
uniform vec4 water_bright : source_color = vec4(0.14, 0.88, 0.84, 1.0);
uniform vec4 caustic_color : source_color = vec4(0.85, 1.0, 0.96, 0.45);
uniform vec4 shimmer_color : source_color = vec4(0.85, 1.0, 0.95, 1.0);

// Animation Controls
uniform float speed : hint_range(0.05, 1.0) = 0.22;
uniform float scale : hint_range(1.0, 15.0) = 4.2;
uniform float caustic_strength : hint_range(0.0, 1.0) = 0.45;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

// 2D Organic Voronoi Caustics
float voronoi_caustic(vec2 uv, float t) {
	vec2 g = floor(uv);
	vec2 f = fract(uv);
	float m_dist = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 p = hash2(g + neighbor);
			p = 0.5 + 0.4 * sin(t + 6.2831 * p);
			vec2 diff = neighbor + p - f;
			float dist = length(diff);
			m_dist = min(m_dist, dist);
		}
	}
	return smoothstep(0.04, 0.38, m_dist);
}

void fragment() {
	vec2 uv = UV * scale;
	float t = TIME * speed;

	// Smooth dual-layered fluid currents
	vec2 flow1 = vec2(sin(uv.y * 1.4 + t * 0.7), cos(uv.x * 1.4 + t * 0.5)) * 0.18;
	vec2 flow2 = vec2(cos(uv.y * 1.8 - t * 0.6), sin(uv.x * 1.8 - t * 0.4)) * 0.15;

	// Deep emerald/lagoon foundation
	float depth_wave = 0.5 + 0.5 * sin(uv.y * 1.0 + flow1.x * 2.5 + t * 0.8);
	vec4 base_col = mix(water_deep, water_mid, depth_wave);
	
	// Sunlit clear turquoise shallows
	float shallow_wave = 0.5 + 0.5 * sin(uv.x * 1.4 - uv.y * 0.9 + flow2.y * 3.0 + t * 1.0);
	base_col = mix(base_col, water_bright, shallow_wave * 0.6);

	// Organic dancing caustic webs
	float c1 = voronoi_caustic((uv + flow1) * 1.4, t * 1.2);
	float c2 = voronoi_caustic((uv + flow2) * 2.0 + vec2(2.3, 1.8), t * 1.5);
	float caustic_web = (1.0 - c1) * 0.55 + (1.0 - c2) * 0.45;
	caustic_web = smoothstep(0.18, 0.62, caustic_web);

	// Subtle sun sparkle shimmer at wave intersections (soft natural highlights)
	float shimmer = smoothstep(0.70, 0.92, (1.0 - c2) * (1.0 - c1));

	vec4 final_col = mix(base_col, caustic_color, caustic_web * caustic_strength);
	final_col += vec4(shimmer_color.rgb, 0.0) * shimmer * 0.35;

	COLOR = final_col;
}
