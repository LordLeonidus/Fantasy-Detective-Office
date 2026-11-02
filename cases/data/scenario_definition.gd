class_name ScenarioDefinition
extends Resource
## Содержание сценария: все факты, очередь посетителей, дела сверху, отделы с таблицей
## результатов поручений и карточки картотеки.

@export var facts: Array[FactDefinition] = []
## Очередь в коридоре по порядку. Кого не приняли до конца дня, ждёт следующего.
@export var visitors: Array[VisitorDefinition] = []
## Дела, которые придут сверху в заданные дни.
@export var cases_from_above: Array[ScheduledCase] = []
@export var departments: Array[DepartmentDefinition] = []
@export var outcomes: Array[OrderOutcome] = []
@export var person_records: Array[PersonRecord] = []
## От чьего имени приходят дела сверху.
@export var command_speaker: SpeakerDefinition
## От чьего имени записи из картотеки.
@export var card_index_speaker: SpeakerDefinition


## Факт по идентификатору или `null`.
func find_fact(fact_id: StringName) -> FactDefinition:
	for fact: FactDefinition in facts:
		if fact.id == fact_id:
			return fact
	return null


## Результат поручения о факте по делу или `null`, если особого результата нет.
func find_outcome(action: DepartmentAction, fact: FactDefinition, case_definition: CaseDefinition) -> OrderOutcome:
	for outcome: OrderOutcome in outcomes:
		if outcome.matches(action, fact, case_definition):
			return outcome
	return null


## Ошибки содержания: повторы идентификаторов, разметка и таблицы со ссылками на факты,
## которых нет в списке сценария. Пустой список — всё в порядке.
func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary[StringName, bool] = {}
	for fact: FactDefinition in facts:
		if seen.has(fact.id):
			errors.append("Факт %s объявлен дважды" % fact.id)
		if fact.note.strip_edges().is_empty():
			errors.append("Факт %s: нет записи для блокнота" % fact.id)
		seen[fact.id] = true
	if command_speaker == null or card_index_speaker == null:
		errors.append("Не назначены начальство или картотека")
	for visitor: VisitorDefinition in visitors:
		for text: String in visitor.get_all_texts():
			_check_markup(text, visitor.id, seen, errors)
		for entry: KnowledgeEntry in visitor.knowledge:
			if entry.fact == null or entry.question == null:
				errors.append("%s: в таблице знаний строка без факта или вопроса" % visitor.id)
			elif not seen.has(entry.fact.id):
				errors.append("%s: в таблице знаний факт %s, которого нет в сценарии" % [visitor.id, entry.fact.id])
		if visitor.fallback_replies.is_empty():
			errors.append("%s: нет ответов «нечего сказать»" % visitor.id)
	for scheduled: ScheduledCase in cases_from_above:
		if scheduled.case_definition == null:
			errors.append("Дело сверху на день %d не назначено" % scheduled.day)
	for definition: CaseDefinition in _all_case_definitions():
		_check_markup(definition.briefing, definition.id, seen, errors)
	for department: DepartmentDefinition in departments:
		for action: DepartmentAction in department.actions:
			_check_markup(action.fallback_result, action.id, seen, errors)
	for outcome: OrderOutcome in outcomes:
		if outcome.action == null or outcome.fact == null:
			errors.append("В таблице результатов строка без поручения или факта")
			continue
		if not seen.has(outcome.fact.id):
			errors.append("Результат %s: факт %s, которого нет в сценарии" % [outcome.action.id, outcome.fact.id])
		_check_markup(outcome.result, outcome.action.id, seen, errors)
	for record: PersonRecord in person_records:
		_check_markup(record.text, record.id, seen, errors)
	return errors


## Все дела сценария: заявления посетителей, дела сверху и то, во что вырастают отказы.
func _all_case_definitions() -> Array[CaseDefinition]:
	var pending: Array[CaseDefinition] = []
	for visitor: VisitorDefinition in visitors:
		if visitor.case_definition != null:
			pending.append(visitor.case_definition)
	for scheduled: ScheduledCase in cases_from_above:
		if scheduled.case_definition != null:
			pending.append(scheduled.case_definition)
	var result: Array[CaseDefinition] = []
	while not pending.is_empty():
		var definition: CaseDefinition = pending.pop_back()
		if result.has(definition):
			continue
		result.append(definition)
		if definition.escalation != null:
			pending.append(definition.escalation)
	return result


func _check_markup(text: String, owner_id: StringName, seen: Dictionary[StringName, bool], errors: Array[String]) -> void:
	for fact_id: StringName in SpeechParser.extract_fact_ids(text):
		if not seen.has(fact_id):
			errors.append("%s: в тексте факт %s, которого нет в сценарии" % [owner_id, fact_id])
