class_name ClockDebugPanel
extends PanelContainer
## Отладочная панель часов: показывает время, ползунком выставляет его напрямую,
## кнопками продвигает так, как будут продвигать действия игрока, и перемешивает узор окон.

## Нажата кнопка «новые окна»: выбрать другой узор горящих окон в домах за окном.
signal window_lights_reshuffle_requested

const QUESTION_BUTTON_TEXT := "Вопрос +%d мин"
const TRIP_BUTTON_TEXT := "Выезд +%d мин"

## На сколько минут продвигает кнопка «вопрос».
@export var question_minutes: int = 10
## На сколько минут продвигает кнопка «выезд».
@export var trip_minutes: int = 60
## Границы ползунка, минуты от полуночи.
@export var slider_min_minute: int = 480
@export var slider_max_minute: int = 1320

var _clock: GameClock

@onready var _clock_label: Label = %ClockLabel
@onready var _time_slider: HSlider = %TimeSlider
@onready var _question_button: Button = %QuestionButton
@onready var _trip_button: Button = %TripButton
@onready var _reshuffle_windows_button: Button = %ReshuffleWindowsButton


func _ready() -> void:
	_time_slider.min_value = slider_min_minute
	_time_slider.max_value = slider_max_minute
	_time_slider.step = 1.0
	_question_button.text = QUESTION_BUTTON_TEXT % question_minutes
	_trip_button.text = TRIP_BUTTON_TEXT % trip_minutes
	_time_slider.value_changed.connect(_on_slider_value_changed)
	_question_button.pressed.connect(_on_question_pressed)
	_trip_button.pressed.connect(_on_trip_pressed)
	_reshuffle_windows_button.pressed.connect(window_lights_reshuffle_requested.emit)


## Начать показывать и двигать часы `clock`.
func bind(clock: GameClock) -> void:
	_clock = clock
	_clock.time_advanced.connect(_refresh)
	_clock.time_set.connect(_refresh)
	_refresh(_clock.get_minute())


func _refresh(minute: int) -> void:
	_clock_label.text = GameClock.format(minute)
	_time_slider.set_value_no_signal(minute)


func _on_slider_value_changed(value: float) -> void:
	_clock.set_time(roundi(value))


func _on_question_pressed() -> void:
	_clock.advance(question_minutes)


func _on_trip_pressed() -> void:
	_clock.advance(trip_minutes)
