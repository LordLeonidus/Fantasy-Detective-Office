class_name CardIndex
extends RefCounted
## Картотека жителей: поиск карточек по словам. Бесплатно. Текст карточки — реплика
## от имени картотеки, фразы из него можно записать в блокнот.

var _scenario: ScenarioDefinition


func _init(scenario: ScenarioDefinition) -> void:
	_scenario = scenario


## Карточки под запрос, текстом для показа. Пустой запрос — ничего: картотеку не листают целиком.
func search(query: String) -> Array[SpokenLine]:
	var lines: Array[SpokenLine] = []
	if query.strip_edges().is_empty():
		return lines
	for record: PersonRecord in _scenario.person_records:
		if record.matches(query):
			lines.append(SpokenLine.new(_scenario.card_index_speaker, SpeechParser.parse(record.text, _scenario)))
	return lines
