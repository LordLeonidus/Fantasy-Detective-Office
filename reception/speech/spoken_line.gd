class_name SpokenLine
extends RefCounted
## Одна сказанная реплика: кто сказал и из каких кусков она состоит.

var speaker: VisitorDefinition
var chunks: Array[SpeechChunk]


func _init(line_speaker: VisitorDefinition, line_chunks: Array[SpeechChunk]) -> void:
	speaker = line_speaker
	chunks = line_chunks
