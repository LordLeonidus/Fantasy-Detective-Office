shader_type canvas_item;
// Смесь двух совпадающих до пикселя картинок одного слоя: from_texture, поверх него
// to_texture с долей weight. Собственная текстура узла задаёт только размер.

uniform sampler2D from_texture : source_color, filter_linear;
uniform sampler2D to_texture : source_color, filter_linear;
uniform float weight : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 from_color = texture(from_texture, UV);
	vec4 to_color = texture(to_texture, UV);
	COLOR = mix(from_color, to_color, weight);
}
