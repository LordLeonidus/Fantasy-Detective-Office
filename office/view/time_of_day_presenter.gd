class_name TimeOfDayPresenter
extends Node
## Показывает время суток в кабинете: по часам `GameClock` смешивает состояния слоёв,
## освещает спрайты поверх комнаты картой света и зажигает окна в домах за окном.
## Продвижение часов показывается плавным переходом, выставленное напрямую время — сразу.

@export var cycle: TimeOfDayCycle
## Слои с картинкой на каждое состояние: небо, город, комната, стол.
@export var layers: Array[TimeOfDayLayer] = []
## Свет комнаты для посетителя, предметов и тюля.
@export var light_map: LightMap
@export var window_lights: WindowLightsLayer
@export var window_lights_schedule: WindowLightsSchedule
## За сколько секунд свет догоняет продвинувшиеся часы.
@export var transition_duration: float = 1.5

var _shown_minute: float
var _tween: Tween


func _ready() -> void:
	assert(cycle != null, "%s: не назначен цикл времени суток" % name)
	assert(window_lights_schedule != null, "%s: не назначено расписание окон" % name)
	assert(light_map != null, "%s: не назначена карта света" % name)
	assert(
		light_map.get_state_count() == cycle.get_keyframe_count(),
		"%s: карт света не столько, сколько ключевых кадров" % name
	)
	for layer: TimeOfDayLayer in layers:
		assert(
			layer.get_state_count() == cycle.get_keyframe_count(),
			"%s: картинок в слое %s не столько, сколько ключевых кадров" % [name, layer.name]
		)


## Начать показывать часы `clock`.
func bind(clock: GameClock) -> void:
	clock.time_advanced.connect(_on_time_advanced)
	clock.time_set.connect(_on_time_set)
	_show_minute(float(clock.get_minute()))


## Выбрать новый узор окон в домах за окном: другие окна загорятся в другом порядке.
func reshuffle_window_lights(rng: RandomNumberGenerator) -> void:
	window_lights.reshuffle(rng)


func _on_time_advanced(minute: int) -> void:
	_stop_transition()
	_tween = create_tween()
	_tween.tween_method(_show_minute, _shown_minute, float(minute), transition_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)


func _on_time_set(minute: int) -> void:
	_stop_transition()
	_show_minute(float(minute))


func _stop_transition() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _show_minute(minute: float) -> void:
	_shown_minute = minute
	var blend: TimeOfDayBlend = cycle.blend_at(minute)
	for layer: TimeOfDayLayer in layers:
		layer.show_blend(blend)
	light_map.show_blend(blend)
	window_lights.show_lit_fraction(window_lights_schedule.lit_fraction_at(minute))
