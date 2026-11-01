class_name SpeechChunk
extends RefCounted
## Кусок реплики: либо смысловая фраза с фактом (её можно записать в блокнот целиком,
## клик по любому её слову), либо обычный текст между фразами, который не записывается.

var text: String
## Факт за фразой или `null`, если это обычный текст.
var fact: FactDefinition


func _init(chunk_text: String, chunk_fact: FactDefinition) -> void:
	text = chunk_text
	fact = chunk_fact


func is_capturable() -> bool:
	return fact != null
