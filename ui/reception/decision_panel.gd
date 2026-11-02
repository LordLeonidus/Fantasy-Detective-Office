class_name DecisionPanel
extends PanelContainer
## Плашка решения: выпадающий список (принять, отказать, отговорить) и «Оформить»,
## вызов следующего и сколько ждут в коридоре.

signal decision_requested(decision: Reception.Decision)
signal call_next_requested

const WAITING_TEXT := "В коридоре: %d"
const NOBODY_WAITING_TEXT := "В коридоре никого"
const CLOSED_TEXT := "Приём окончен, в коридоре: %d"
## Пункты списка решений по порядку.
const DECISION_ITEMS: Array[Array] = [
	[Reception.Decision.ACCEPT, "Принять заявление"],
	[Reception.Decision.REFUSE, "Отказать"],
	[Reception.Decision.TALK_OUT, "Отговорить"],
]

@onready var _queue_label: Label = %QueueLabel
@onready var _decision_option: OptionButton = %DecisionOption
@onready var _apply_button: Button = %ApplyButton
@onready var _call_next_button: Button = %CallNextButton


func _ready() -> void:
	for item: Array in DECISION_ITEMS:
		_decision_option.add_item(item[1], item[0])
	_apply_button.pressed.connect(_on_apply_pressed)
	_call_next_button.pressed.connect(call_next_requested.emit)


## Обновить плашку: решать можно, когда напротив кто-то сидит; звать — когда место свободно,
## приём открыт и в коридоре есть люди.
func show_state(has_visitor: bool, waiting_count: int, reception_open: bool) -> void:
	_decision_option.disabled = not has_visitor
	_apply_button.disabled = not has_visitor
	_call_next_button.disabled = has_visitor or waiting_count == 0 or not reception_open
	if not reception_open:
		_queue_label.text = CLOSED_TEXT % waiting_count
	elif waiting_count > 0:
		_queue_label.text = WAITING_TEXT % waiting_count
	else:
		_queue_label.text = NOBODY_WAITING_TEXT


func _on_apply_pressed() -> void:
	decision_requested.emit(_decision_option.get_selected_id() as Reception.Decision)
