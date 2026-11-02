class_name InboxDocument
extends RefCounted
## Бумага во входящих: результат поручения или вводная дела сверху. Текст — реплика
## от имени отдела или начальства, смысловые фразы в нём можно записать в блокнот.

var title: String
var line: SpokenLine
var day: int
var minute: int
var is_read: bool = false


func _init(document_title: String, document_line: SpokenLine, arrival_day: int, arrival_minute: int) -> void:
	title = document_title
	line = document_line
	day = arrival_day
	minute = arrival_minute
