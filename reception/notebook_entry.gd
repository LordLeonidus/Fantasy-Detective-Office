class_name NotebookEntry
extends RefCounted
## Запись в блокноте: истолкованная следователем фраза (текст — `FactDefinition.note`)
## и кто её сказал. Пока человек сидит напротив, запись можно убрать; когда он уходит,
## записи с его слов закрепляются.

var fact: FactDefinition
var source: VisitorDefinition
var is_fixed: bool = false


func _init(entry_fact: FactDefinition, entry_source: VisitorDefinition) -> void:
	fact = entry_fact
	source = entry_source


func get_text() -> String:
	return fact.note
