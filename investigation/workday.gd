class_name Workday
extends RefCounted
## Рабочий день: до конца дня принимают посетителей, после — только закончить день.
## Закончить день можно в любой момент, когда напротив никто не сидит. Ночью готовы
## поручения, утром приходят дела сверху.

## Приём открылся или закрылся по часам.
signal reception_open_changed(is_open: bool)
## Наступило утро нового дня.
signal day_started(day: int)

var _clock: GameClock
var _rules: InvestigationRules
var _reception: Reception
var _was_open: bool


func _init(clock: GameClock, rules: InvestigationRules, reception: Reception) -> void:
	_clock = clock
	_rules = rules
	_reception = reception
	_was_open = is_reception_open()
	# Методы, а не лямбды: лямбда с `self` держала бы этот объект и замкнула цикл ссылок с часами.
	_clock.time_advanced.connect(_on_clock_changed)
	_clock.time_set.connect(_on_clock_changed)
	_clock.day_started.connect(day_started.emit)


func get_day() -> int:
	return _clock.get_day()


## Можно ли звать посетителей: рабочий день ещё не кончился.
func is_reception_open() -> bool:
	return _clock.get_minute() < _rules.day_end_minute


## Можно ли закончить день: напротив никто не сидит.
func can_end_day() -> bool:
	return not _reception.has_visitor()


func end_day() -> void:
	assert(can_end_day(), "Нельзя уйти, пока напротив сидит посетитель")
	_clock.start_next_day(_rules.day_start_minute)


func _on_clock_changed(_minute: int) -> void:
	var open: bool = is_reception_open()
	if open == _was_open:
		return
	_was_open = open
	reception_open_changed.emit(open)
