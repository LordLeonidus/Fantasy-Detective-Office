class_name TimeOfDayBlend
extends RefCounted
## Смесь двух соседних состояний времени суток: показать `from_index`, поверх него
## `to_index` с долей `weight` (0 — только первое, 1 — только второе).

var from_index: int
var to_index: int
var weight: float


func _init(from: int, to: int, blend_weight: float) -> void:
	from_index = from
	to_index = to
	weight = blend_weight
