shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// =========================
// Scanlines
// =========================
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.14;
uniform float scanline_count : hint_range(10.0, 1200.0) = 320.0;
uniform float scanline_thickness : hint_range(0.01, 1.0) = 0.18;
uniform float scanline_scroll_speed : hint_range(0.0, 2.0) = 0.08;

// =========================
// Noise
// =========================
uniform float noise_strength : hint_range(0.0, 1.0) = 0.05;
uniform float noise_scale : hint_range(1.0, 2000.0) = 900.0;
uniform float noise_speed : hint_range(0.0, 5.0) = 1.2;

// =========================
// Horizontal glitch
// =========================
uniform float glitch_strength : hint_range(0.0, 1.0) = 0.18;
uniform float glitch_frequency : hint_range(0.0, 1.0) = 0.06;
uniform float glitch_refresh_rate : hint_range(1.0, 60.0) = 12.0;
uniform float glitch_band_count : hint_range(1.0, 200.0) = 60.0;
uniform float glitch_band_probability : hint_range(0.0, 1.0) = 0.22;

// =========================
// Helpers
// =========================
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// -------------------------------------------------
	// 1) Glitch horizontal parametrizable
	// -------------------------------------------------
	// Se evalúa en "bloques" de tiempo para que el glitch
	// no cambie cada frame de forma caótica.
	float glitch_time = floor(TIME * glitch_refresh_rate);

	// Determina si en este instante hay "evento de glitch".
	float glitch_event = step(1.0 - glitch_frequency, hash(vec2(glitch_time, 19.37)));

	// Divide la pantalla en bandas horizontales y decide
	// cuáles se desplazan durante ese evento.
	float band_id = floor(uv.y * glitch_band_count);
	float band_mask = step(
		1.0 - glitch_band_probability,
		hash(vec2(glitch_time, band_id))
	);

	float glitch_mask = glitch_event * band_mask;

	// Offset horizontal de esas bandas
	float band_offset = (hash(vec2(band_id, glitch_time + 7.13)) - 0.5) * 2.0;
	uv.x += band_offset * glitch_strength * 0.05 * glitch_mask;

	// Clamp para evitar lecturas fuera de pantalla
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	// -------------------------------------------------
	// 2) Leer pantalla
	// -------------------------------------------------
	vec4 col = textureLod(screen_texture, uv, 0.0);

	// -------------------------------------------------
	// 3) Scanlines reales moviéndose hacia arriba
	// -------------------------------------------------
	// uv.y va de 0 arriba a 1 abajo.
	// Al sumar TIME * speed, las líneas aparentan subir.
	float scan_pos = fract((SCREEN_UV.y + TIME * scanline_scroll_speed) * scanline_count);

	// Línea fina: vale 1 dentro de la línea, 0 fuera.
	float scanline = 1.0 - step(scanline_thickness, scan_pos);

	// Aplicar oscurecimiento sólo dentro de la línea.
	float scan_mul = mix(1.0, 1.0 - scanline_strength, scanline);

	// -------------------------------------------------
	// 4) Ruido sutil
	// -------------------------------------------------
	float n = hash(floor(SCREEN_UV * noise_scale) + floor(TIME * noise_speed * 60.0));
	float noise_mul = mix(1.0, 1.0 - noise_strength, n);

	// -------------------------------------------------
	// 5) Resultado final
	// -------------------------------------------------
	col.rgb *= scan_mul;
	col.rgb *= noise_mul;

	COLOR = vec4(col.rgb, 1.0);
}