@abstract
class_name SpeechParser
extends RefCounted
## Делит размеченную реплику на куски. Разметка `[текст|id]` — смысловая фраза с фактом `id`,
## остальной текст (служебные слова, обороты вне фактов, знаки препинания) не записывается.

const PHRASE_PATTERN := "\\[([^\\]|]+)\\|([a-z0-9_]+)\\]"

static var _phrase_regex: RegEx


## Куски реплики по порядку. Фраза с неизвестным фактом становится обычным текстом.
static func parse(markup: String, scenario: ScenarioDefinition) -> Array[SpeechChunk]:
	var chunks: Array[SpeechChunk] = []
	var cursor: int = 0
	for found: RegExMatch in _get_phrase_regex().search_all(markup):
		_append_plain(chunks, markup.substr(cursor, found.get_start() - cursor))
		var fact: FactDefinition = scenario.find_fact(StringName(found.get_string(2)))
		if fact != null:
			chunks.append(SpeechChunk.new(found.get_string(1), fact))
		else:
			_append_plain(chunks, found.get_string(1))
		cursor = found.get_end()
	_append_plain(chunks, markup.substr(cursor))
	return chunks


## Идентификаторы фактов, размеченных в тексте.
static func extract_fact_ids(markup: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for found: RegExMatch in _get_phrase_regex().search_all(markup):
		ids.append(StringName(found.get_string(2)))
	return ids


static func _append_plain(chunks: Array[SpeechChunk], plain: String) -> void:
	if not plain.is_empty():
		chunks.append(SpeechChunk.new(plain, null))


static func _get_phrase_regex() -> RegEx:
	if _phrase_regex == null:
		_phrase_regex = RegEx.create_from_string(PHRASE_PATTERN)
	return _phrase_regex
