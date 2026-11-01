shader_type canvas_item;
// Спрайт поверх комнаты (посетитель, предметы, тюль), освещённый картой света комнаты.
// Карта говорит, во сколько раз каждое место кадра светлее или темнее дня и какого оттенка,
// значение записано делённым на MAP_RANGE. Две карты смешиваются так же, как слои комнаты.
// Карта растянута на всю сцену, поэтому берётся по положению пикселя в сцене, а не по UV спрайта.

uniform sampler2D from_map : filter_linear, repeat_disable;
uniform sampler2D to_map : filter_linear, repeat_disable;
uniform float weight : hint_range(0.0, 1.0) = 0.0;
// Размер сцены, на которую растянута карта.
uniform vec2 scene_size = vec2(1920.0, 1080.0);

const float MAP_RANGE = 2.0;

varying vec2 scene_uv;

void vertex() {
	scene_uv = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy / scene_size;
}

void fragment() {
	vec3 from_light = texture(from_map, scene_uv).rgb;
	vec3 to_light = texture(to_map, scene_uv).rgb;
	vec3 light = mix(from_light, to_light, weight) * MAP_RANGE;
	// COLOR здесь уже цвет текстуры, умноженный на цвет вершины и modulate (появление посетителя).
	COLOR.rgb *= light;
}
