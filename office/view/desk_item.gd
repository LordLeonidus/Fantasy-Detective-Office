class_name DeskItem
extends Button
## Предмет на столе. Клик открывает или закрывает его крупный план `view`. Пока кнопка-заглушка:
## настоящий спрайт появится позже. Счётчик (`set_badge`) показывает, сколько нового, например
## непрочитанных бумаг во входящих.

const BADGE_TEXT := "%s (%d)"

@export var view: CloseupView
@export var title: String


func _ready() -> void:
	text = title
	pressed.connect(view.toggle)


## Показать число рядом с названием; 0 — без числа.
func set_badge(count: int) -> void:
	text = BADGE_TEXT % [title, count] if count > 0 else title
