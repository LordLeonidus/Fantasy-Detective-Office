class_name VisitorView
extends TextureRect
## Посетитель на стуле напротив. Место на стуле — положение узла в сцене. Входит со стороны
## двери (смещение `enter_offset`) и проявляется, уходит туда же, растворяясь.
## Масштаб посетителя (`VisitorDefinition.portrait_scale`) применяется вокруг `pivot_offset`,
## поставленного в сцене на точку посадки, поэтому любой посетитель сидит на сиденье.

## Откуда входит и куда уходит, относительно места на стуле.
@export var enter_offset: Vector2 = Vector2(160.0, -30.0)
@export var move_duration: float = 0.6
## Сколько секунд посетитель ещё сидит после решения, чтобы прочитать его ответ.
@export var leave_delay: float = 1.5

var _seat_position: Vector2
var _tween: Tween


func _ready() -> void:
	_seat_position = position
	modulate.a = 0.0


## Посетитель входит и садится.
func show_visitor(visitor: VisitorDefinition) -> void:
	texture = visitor.portrait
	scale = Vector2.ONE * visitor.portrait_scale
	_stop_tween()
	position = _seat_position + enter_offset
	modulate.a = 0.0
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", _seat_position, move_duration)
	_tween.tween_property(self, "modulate:a", 1.0, move_duration)


## Посетитель встаёт и уходит.
func hide_visitor() -> void:
	_stop_tween()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_interval(leave_delay)
	_tween.tween_property(self, "position", _seat_position + enter_offset, move_duration)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, move_duration)


func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
