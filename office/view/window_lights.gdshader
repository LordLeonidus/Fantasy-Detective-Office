shader_type canvas_item;
// Горящие окна домов за окном кабинета. Каждое окно загорается само по себе: у окна
// есть номер, из номера и зерна дня получается случайный порог, и окно горит, когда
// доля горящих окон lit_fraction выше его порога. Новое зерно — другой набор и порядок окон.

uniform sampler2D light_color : source_color, filter_linear;
uniform sampler2D window_ids : filter_nearest;
uniform float lit_fraction : hint_range(0.0, 1.0) = 0.0;
// Ширина перехода порога: окно вспыхивает почти сразу, но без щелчка.
uniform float switch_softness : hint_range(0.001, 0.1) = 0.015;
uniform float pattern_seed = 0.0;

const float MAX_WINDOW_ID = 255.0;

float window_threshold(float window_id) {
	return fract(sin(window_id * 127.1 + pattern_seed * 311.7) * 43758.5453);
}

void fragment() {
	vec4 light = texture(light_color, UV);
	float window_id = floor(texture(window_ids, UV).r * MAX_WINDOW_ID + 0.5);
	float is_window = step(0.5, window_id);
	float threshold = window_threshold(window_id);
	float lit = 1.0 - smoothstep(lit_fraction - switch_softness, lit_fraction, threshold);
	COLOR = vec4(light.rgb, light.a * lit * is_window);
}
