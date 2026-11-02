class_name CaseDefinition
extends Resource
## Дело. Его заводит принятое заявление посетителя или оно приходит в отдел сверху готовым,
## с вводной. Раскрытое дело приносит отделу награду.

@export var id: StringName
@export var title: String
## Коротко, о чём дело: показывается в папке.
@export_multiline var summary: String
## Награда отделу за раскрытие, в серебре.
@export var reward: int = 0
## Вводная дела сверху: приходит во входящие, смысловые фразы `[текст|id]` можно записать.
@export_multiline var briefing: String
## Дело, которое придёт сверху, если заявление не принять. Пусто — отказ ничего не вызывает.
@export var escalation: CaseDefinition
## Через сколько дней после отказа приходит дело сверху.
@export var escalation_delay_days: int = 1
