class_name ReceptionDayDefinition
extends Resource
## Содержание приёмного дня: все факты дня и очередь посетителей по порядку.

@export var facts: Array[FactDefinition] = []
@export var visitors: Array[VisitorDefinition] = []


## Факт по идентификатору или `null`.
func find_fact(fact_id: StringName) -> FactDefinition:
	for fact: FactDefinition in facts:
		if fact.id == fact_id:
			return fact
	return null


## Ошибки содержания: повторы идентификаторов, разметка и таблицы знаний со ссылками
## на факты, которых нет в списке дня. Пустой список — всё в порядке.
func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary[StringName, bool] = {}
	for fact: FactDefinition in facts:
		if seen.has(fact.id):
			errors.append("Факт %s объявлен дважды" % fact.id)
		if fact.note.strip_edges().is_empty():
			errors.append("Факт %s: нет записи для блокнота" % fact.id)
		seen[fact.id] = true
	for visitor: VisitorDefinition in visitors:
		for text: String in visitor.get_all_texts():
			for fact_id: StringName in SpeechParser.extract_fact_ids(text):
				if not seen.has(fact_id):
					errors.append("%s: в реплике факт %s, которого нет в дне" % [visitor.id, fact_id])
		for entry: KnowledgeEntry in visitor.knowledge:
			if entry.fact == null or entry.question == null:
				errors.append("%s: в таблице знаний строка без факта или вопроса" % visitor.id)
			elif not seen.has(entry.fact.id):
				errors.append("%s: в таблице знаний факт %s, которого нет в дне" % [visitor.id, entry.fact.id])
		if visitor.fallback_replies.is_empty():
			errors.append("%s: нет ответов «нечего сказать»" % visitor.id)
	return errors
