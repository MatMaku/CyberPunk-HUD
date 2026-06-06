shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

// Margen entre el borde del overlay y el panel real.
// El overlay debe ser más grande que el panel.
uniform vec2 inner_margin = vec2(0.08, 0.08);

// Borde interno
uniform float edge_width : hint_range(0.0, 0.25) = 0.035;
uniform float inner_softness : hint_range(0.0, 0.2) = 0.02;

// Fade hacia afuera
uniform float outer_fade : hint_range(0.0, 0.25) = 0.08;

// Glitch
uniform float glitch_strength : hint_range(0.0, 0.05) = 0.014;
uniform float glitch_speed : hint_range(0.0, 20.0) = 7.0;
uniform float slice_count : hint_range(1.0, 400.0) = 110.0;

// Holograma
uniform float rgb_split : hint_range(0.0, 0.02) = 0.0035;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.20;
uniform float scanline_freq : hint_range(10.0, 3000.0) = 850.0;
uniform float shimmer : hint_range(0.0, 1.0) = 0.22;
uniform vec4 holo_tint : source_color = vec4(0.35, 0.9, 1.0, 1.0);

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float rect_sdf(vec2 uv, vec2 margin) {
	vec2 p = uv - vec2(0.5);
	vec2 half_size = vec2(0.5) - margin;
	vec2 q = abs(p) - half_size;
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}

void fragment() {
	float sdf = rect_sdf(UV, inner_margin);

	float inside = 1.0 - step(0.0, sdf);
	float outside = step(0.0, sdf);

	// Máscara interna: visible cerca del borde hacia adentro
	float inside_mask = 1.0 - smoothstep(edge_width, edge_width + inner_softness, -sdf);

	// Máscara externa: visible justo afuera y se desvanece suave
	float outside_mask = pow(1.0 - smoothstep(0.0, outer_fade, sdf), 1.35);

	float edge = inside_mask * inside + outside_mask * outside;
	edge = clamp(edge, 0.0, 1.0);

	vec2 suv = SCREEN_UV;

	// --- Glitch más equilibrado ---
	float t = TIME * glitch_speed;
	float slice_id = floor(UV.y * slice_count);

	float gate = step(0.74, hash12(vec2(slice_id, floor(t))));
	float magnitude = hash12(vec2(slice_id + 13.7, floor(t * 1.07)));
	float direction = mix(-1.0, 1.0, step(0.5, hash12(vec2(slice_id + 41.2, floor(t * 0.93)))));

	float x_offset = direction * magnitude * glitch_strength * gate * edge;
	suv.x += x_offset;

	float y_jitter = (hash12(vec2(slice_id + 91.0, floor(t * 1.31))) - 0.5) * 0.0015;
	suv.y += y_jitter * gate * edge;

	// RGB split simétrico respecto al centro
	float side = sign(UV.x - 0.5);
	if (side == 0.0) {
		side = 1.0;
	}
	vec2 split = vec2(rgb_split * edge * side, 0.0);

	float r = texture(screen_tex, suv + split).r;
	float g = texture(screen_tex, suv).g;
	float b = texture(screen_tex, suv - split).b;

	vec3 col = vec3(r, g, b);

	// Scanlines
	float scan = sin((suv.y * scanline_freq) + TIME * 8.0) * 0.5 + 0.5;
	col *= 1.0 - (scanline_strength * edge) + (scanline_strength * edge) * scan;

	// Shimmer holográfico
	float sh = sin((suv.x * 120.0) + TIME * 14.0) * 0.5 + 0.5;
	col += holo_tint.rgb * (shimmer * edge) * (sh * 0.25);

	// Tint
	col = mix(col, col + holo_tint.rgb * 0.22, edge);

	float alpha = edge;
	COLOR = vec4(col, alpha);
}