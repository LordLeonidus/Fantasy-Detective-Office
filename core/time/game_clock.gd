class_name GameClock
extends RefCounted
## Игровые часы: текущее время дня в минутах от полуночи. Логика без представления.
## Время двигают действия игрока (`advance`), отладка может выставить его напрямую (`set_time`).

## Время продвинулось действием игрока. Представление показывает это плавным переходом.
signal time_advanced(minute: int)
## Время выставлено напрямую (отладка, начало дня). Представление показывает его сразу.
signal time_set(minute: int)

const MINUTES_PER_HOUR := 60
const MINUTES_PER_DAY := 1440

var _minute: int


func _init(start_minute: int) -> void:
	_minute = start_minute


## Текущее время в минутах от полуночи.
func get_minute() -> int:
	return _minute


## Продвинуть время на `minutes` минут.
func advance(minutes: int) -> void:
	assert(minutes > 0, "Время можно только продвигать вперёд")
	_minute += minutes
	time_advanced.emit(_minute)


## Выставить время напрямую.
func set_time(minute: int) -> void:
	_minute = minute
	time_set.emit(_minute)


## Время в виде «ЧЧ:ММ».
static func format(minute: int) -> String:
	@warning_ignore("integer_division")
	var hours: int = minute / MINUTES_PER_HOUR
	var minutes: int = minute % MINUTES_PER_HOUR
	return "%02d:%02d" % [hours, minutes]
