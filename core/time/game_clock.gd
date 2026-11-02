class_name GameClock
extends RefCounted
## Игровые часы: номер дня (с 1) и время дня в минутах от полуночи. Логика без представления.
## Время двигают действия игрока (`advance`), отладка может выставить его напрямую (`set_time`),
## новый день начинается `start_day`.

## Время продвинулось действием игрока. Представление показывает это плавным переходом.
signal time_advanced(minute: int)
## Время выставлено напрямую (отладка, начало дня). Представление показывает его сразу.
signal time_set(minute: int)
## Начался новый день. Сразу за ним приходит `time_set` с временем начала дня.
signal day_started(day: int)

const MINUTES_PER_HOUR := 60
const MINUTES_PER_DAY := 1440

var _day: int = 1
var _minute: int


func _init(start_minute: int) -> void:
	_minute = start_minute


## Текущее время в минутах от полуночи.
func get_minute() -> int:
	return _minute


## Номер текущего дня, считая с 1.
func get_day() -> int:
	return _day


## Минуты от полуночи первого дня: чтобы сравнивать моменты разных дней.
func get_absolute_minute() -> int:
	return (_day - 1) * MINUTES_PER_DAY + _minute


## Продвинуть время на `minutes` минут.
func advance(minutes: int) -> void:
	assert(minutes > 0, "Время можно только продвигать вперёд")
	_minute += minutes
	time_advanced.emit(_minute)


## Выставить время напрямую.
func set_time(minute: int) -> void:
	_minute = minute
	time_set.emit(_minute)


## Начать следующий день в минуту `minute`.
func start_next_day(minute: int) -> void:
	_day += 1
	_minute = minute
	day_started.emit(_day)
	time_set.emit(_minute)


## Время в виде «ЧЧ:ММ».
static func format(minute: int) -> String:
	@warning_ignore("integer_division")
	var hours: int = minute / MINUTES_PER_HOUR
	var minutes: int = minute % MINUTES_PER_HOUR
	return "%02d:%02d" % [hours, minutes]


## Продолжительность в виде «3 ч», «45 мин» или «1 ч 30 мин».
static func format_duration(minutes: int) -> String:
	@warning_ignore("integer_division")
	var hours: int = minutes / MINUTES_PER_HOUR
	var rest: int = minutes % MINUTES_PER_HOUR
	if hours == 0:
		return "%d мин" % rest
	if rest == 0:
		return "%d ч" % hours
	return "%d ч %d мин" % [hours, rest]
