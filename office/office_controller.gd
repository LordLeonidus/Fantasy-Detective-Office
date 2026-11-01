class_name OfficeController
extends Node
## Собирает кабинет: создаёт игровые часы, блокнот и приём и связывает их с показом
## времени суток, приёма и отладочной панелью.

@export var time_of_day: TimeOfDayPresenter
@export var reception_presenter: ReceptionPresenter
@export var clock_debug_panel: ClockDebugPanel
## Кто сегодня придёт и что расскажет.
@export var reception_day: ReceptionDayDefinition
@export var reception_rules: ReceptionRules
## Время начала рабочего дня, минуты от полуночи.
@export var day_start_minute: int = 540

var _clock: GameClock
var _notebook: Notebook
var _reception: Reception
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_clock = GameClock.new(day_start_minute)
	_notebook = Notebook.new()
	_reception = Reception.new(reception_day, reception_rules, _clock, _notebook)
	time_of_day.reshuffle_window_lights(_rng)
	time_of_day.bind(_clock)
	reception_presenter.bind(_reception, _notebook)
	clock_debug_panel.bind(_clock)
	clock_debug_panel.window_lights_reshuffle_requested.connect(_on_window_lights_reshuffle_requested)


func _on_window_lights_reshuffle_requested() -> void:
	time_of_day.reshuffle_window_lights(_rng)
