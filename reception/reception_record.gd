class_name ReceptionRecord
extends RefCounted
## Чем закончился приём посетителя: принятое решение и пытался ли следователь его отговорить.
## Отсюда позже вырастут дела, жалобы и статистика.

var visitor: VisitorDefinition
## Решение есть, только когда `has_decision` истинно.
var decision: Reception.Decision
var has_decision: bool = false
var talk_out_attempted: bool = false


func _init(record_visitor: VisitorDefinition) -> void:
	visitor = record_visitor
