class_name CaseFile
extends RefCounted
## Заведённое дело: что за дело, откуда пришло, когда заведено и раскрыто ли.

enum Status { OPEN, SOLVED }

var definition: CaseDefinition
var status: Status = Status.OPEN
## Посетитель, чьё заявление завело дело; `null` — дело пришло сверху.
var visitor: VisitorDefinition
var opened_day: int


func _init(case_definition: CaseDefinition, case_visitor: VisitorDefinition, day: int) -> void:
	definition = case_definition
	visitor = case_visitor
	opened_day = day


func is_open() -> bool:
	return status == Status.OPEN


func is_from_above() -> bool:
	return visitor == null
