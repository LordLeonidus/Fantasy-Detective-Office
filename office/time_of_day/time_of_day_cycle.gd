class_name TimeOfDayCycle
extends Resource
## Ключевые кадры времени суток: в какую минуту дня каждое состояние показано в чистом виде.
## Между соседними кадрами состояния смешиваются. До первого и после последнего показан
## крайний кадр. Порядок кадров совпадает с порядком текстур в слоях `TimeOfDayLayer`.

## Минуты от полуночи, по возрастанию: утро, день, закат, сумерки, ночь.
@export var keyframe_minutes: PackedInt32Array = PackedInt32Array()


## Число ключевых кадров.
func get_keyframe_count() -> int:
	return keyframe_minutes.size()


## Какие два состояния и в какой доле показать в минуту `minute`.
## Переход между кадрами сглажен: вблизи ключевого кадра свет меняется медленнее.
func blend_at(minute: float) -> TimeOfDayBlend:
	var last: int = keyframe_minutes.size() - 1
	assert(last >= 0, "В цикле времени суток нет ключевых кадров")
	if minute <= keyframe_minutes[0]:
		return TimeOfDayBlend.new(0, 0, 0.0)
	if minute >= keyframe_minutes[last]:
		return TimeOfDayBlend.new(last, last, 0.0)
	var index: int = 0
	while minute > keyframe_minutes[index + 1]:
		index += 1
	var linear: float = inverse_lerp(
		float(keyframe_minutes[index]), float(keyframe_minutes[index + 1]), minute
	)
	return TimeOfDayBlend.new(index, index + 1, smoothstep(0.0, 1.0, linear))
