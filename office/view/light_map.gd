class_name LightMap
extends Resource
## Свет комнаты для спрайтов поверх неё: посетителя, предметов, тюля. На каждое состояние
## времени суток — карта света (`tools/art/make_light_maps.ps1`). Все освещённые спрайты
## используют один общий `material` с шейдером `light_map.gdshader`, поэтому смесь карт
## выставляется один раз на всех.

const FROM_MAP_PARAM := &"from_map"
const TO_MAP_PARAM := &"to_map"
const WEIGHT_PARAM := &"weight"

## Карты в порядке ключевых кадров `TimeOfDayCycle`.
@export var maps: Array[Texture2D] = []
## Общий материал освещённых спрайтов.
@export var material: ShaderMaterial


## Число состояний, для которых есть карты.
func get_state_count() -> int:
	return maps.size()


## Осветить спрайты смесью состояний.
func show_blend(blend: TimeOfDayBlend) -> void:
	material.set_shader_parameter(FROM_MAP_PARAM, maps[blend.from_index])
	material.set_shader_parameter(TO_MAP_PARAM, maps[blend.to_index])
	material.set_shader_parameter(WEIGHT_PARAM, blend.weight)
