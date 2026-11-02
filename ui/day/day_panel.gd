class_name DayPanel
extends PanelContainer
## Плашка дня: какой день, сколько серебра в казне, сколько поручений в работе
## и кнопка «Закончить день».

signal end_day_requested

const DAY_TEXT := "День %d"
const MONEY_TEXT := "Казна: %d сер."
const PENDING_TEXT := "Поручений в работе: %d"
const NO_PENDING_TEXT := "Поручений в работе нет"

@onready var _day_label: Label = %DayLabel
@onready var _money_label: Label = %MoneyLabel
@onready var _pending_label: Label = %PendingLabel
@onready var _end_day_button: Button = %EndDayButton


func _ready() -> void:
	_end_day_button.pressed.connect(end_day_requested.emit)


func show_day(day: int) -> void:
	_day_label.text = DAY_TEXT % day


func show_money(balance: int) -> void:
	_money_label.text = MONEY_TEXT % balance


func show_pending_orders(count: int) -> void:
	_pending_label.text = PENDING_TEXT % count if count > 0 else NO_PENDING_TEXT


func set_end_day_available(available: bool) -> void:
	_end_day_button.disabled = not available
