class_name TimeOfDayLayer
extends TextureRect
## Слой кабинета (небо, город за окном, комната, стол), у которого есть картинка на каждое
## состояние времени суток.
## Показывает смесь двух соседних состояний через шейдер `crossfade.gdshader`.
## Узлу нужен `ShaderMaterial` с этим шейдером; собственная текстура задаёт только размер.

const FROM_TEXTURE_PARAM := &"from_texture"
const TO_TEXTURE_PARAM := &"to_texture"
const WEIGHT_PARAM := &"weight"

## Картинки состояний в порядке ключевых кадров `TimeOfDayCycle`.
@export var textures: Array[Texture2D] = []

var _material: ShaderMaterial


func _ready() -> void:
	_material = material as ShaderMaterial
	assert(_material != null, "%s: нужен ShaderMaterial с crossfade.gdshader" % name)


## Число состояний, для которых есть картинки.
func get_state_count() -> int:
	return textures.size()


## Показать смесь состояний.
func show_blend(blend: TimeOfDayBlend) -> void:
	_material.set_shader_parameter(FROM_TEXTURE_PARAM, textures[blend.from_index])
	_material.set_shader_parameter(TO_TEXTURE_PARAM, textures[blend.to_index])
	_material.set_shader_parameter(WEIGHT_PARAM, blend.weight)
