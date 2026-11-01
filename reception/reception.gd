class_name Reception
extends RefCounted
## Приём посетителей за день. Логика без представления: очередь, кто сейчас сидит напротив,
## что сказано, записи в блокнот, вопросы (стоят времени), решение по заявлению.

enum Decision { ACCEPT, REFUSE, TALK_OUT }

## Вошёл и сел следующий посетитель.
signal visitor_entered(visitor: VisitorDefinition)
## Посетитель что-то сказал: рассказ, ответ на вопрос или реакцию на решение.
signal visitor_spoke(line: SpokenLine)
## Принято решение. `succeeded` ложно, если отговорить не удалось и человек остался.
signal decision_made(visitor: VisitorDefinition, decision: Decision, succeeded: bool)
## Посетитель ушёл, место напротив свободно.
signal visitor_left(visitor: VisitorDefinition)

var _day: ReceptionDayDefinition
var _rules: ReceptionRules
var _clock: GameClock
var _notebook: Notebook
var _next_index: int = 0
var _current: VisitorDefinition
var _records: Array[ReceptionRecord] = []
## Заданные вопросы: ключ — кому, о каком факте и какой вопрос.
var _asked: Dictionary[String, bool] = {}
## Какой ответ «нечего сказать» следующий у каждого посетителя.
var _fallback_index: Dictionary[StringName, int] = {}


func _init(day: ReceptionDayDefinition, rules: ReceptionRules, clock: GameClock, notebook: Notebook) -> void:
	_day = day
	_rules = rules
	_clock = clock
	_notebook = notebook
	for error: String in _day.validate():
		push_error(error)


func has_visitor() -> bool:
	return _current != null


func get_waiting_count() -> int:
	return _day.visitors.size() - _next_index


## Позвать следующего из коридора.
func call_next() -> void:
	assert(not has_visitor(), "Напротив уже сидит посетитель")
	assert(get_waiting_count() > 0, "В коридоре никого")
	_current = _day.visitors[_next_index]
	_next_index += 1
	_records.append(ReceptionRecord.new(_current))
	visitor_entered.emit(_current)
	_speak(_current, _current.monologue)


## Записать фразу сидящего напротив в блокнот или убрать, если она уже записана. Бесплатно.
func toggle_note(fact: FactDefinition, source: VisitorDefinition) -> void:
	if source == _current:
		_notebook.toggle(fact, source)


## Убрать запись со слов сидящего напротив.
func remove_note(entry: NotebookEntry) -> void:
	if entry.source == _current:
		_notebook.remove(entry.fact.id)


## Попросить сидящего напротив рассказать всё с начала.
func retell() -> void:
	assert(has_visitor(), "Просить некого")
	if _rules.retell_minutes > 0:
		_clock.advance(_rules.retell_minutes)
	_speak(_current, _current.monologue)


## Какие вопросы можно задать сидящему напротив о записи. Пусто, если спрашивать некого.
func get_questions(entry: NotebookEntry) -> Array[QuestionTemplate]:
	if not has_visitor():
		return []
	return _rules.question_catalog.questions_for(entry.fact, entry.source == _current)


## Задавали ли уже сидящему напротив этот вопрос об этой записи.
func was_asked(entry: NotebookEntry, question: QuestionTemplate) -> bool:
	return has_visitor() and _asked.has(_asked_key(entry, question))


## Задать вопрос о записи. Стоит времени; на каждый вопрос есть ответ.
func ask(entry: NotebookEntry, question: QuestionTemplate) -> void:
	assert(has_visitor(), "Спрашивать некого")
	_asked[_asked_key(entry, question)] = true
	_clock.advance(_rules.question_minutes)
	var known: KnowledgeEntry = _current.find_answer(entry.fact, question)
	_speak(_current, known.answer if known != null else _next_fallback(_current))


## Решить, что делать с заявлением. Если отговорить не удалось, человек остаётся.
func decide(decision: Decision) -> void:
	assert(has_visitor(), "Решать не по кому")
	var visitor: VisitorDefinition = _current
	var record: ReceptionRecord = _records.back()
	if decision == Decision.TALK_OUT:
		record.talk_out_attempted = true
		if not visitor.can_be_talked_out:
			decision_made.emit(visitor, decision, false)
			_speak(visitor, visitor.talk_out_fail_reply)
			return
	record.decision = decision
	record.has_decision = true
	decision_made.emit(visitor, decision, true)
	_speak(visitor, _reply_for(visitor, decision))
	_current = null
	_notebook.fix_entries_from(visitor)
	visitor_left.emit(visitor)


## Итоги приёма по посетителям, которые уже входили.
func get_records() -> Array[ReceptionRecord]:
	return _records.duplicate()


func _speak(visitor: VisitorDefinition, markup: String) -> void:
	visitor_spoke.emit(SpokenLine.new(visitor, SpeechParser.parse(markup, _day)))


func _next_fallback(visitor: VisitorDefinition) -> String:
	var index: int = _fallback_index.get(visitor.id, 0)
	_fallback_index[visitor.id] = index + 1
	return visitor.fallback_replies[index % visitor.fallback_replies.size()]


func _asked_key(entry: NotebookEntry, question: QuestionTemplate) -> String:
	return "%s|%s|%s" % [_current.id, entry.fact.id, question.id]


func _reply_for(visitor: VisitorDefinition, decision: Decision) -> String:
	match decision:
		Decision.ACCEPT:
			return visitor.accept_reply
		Decision.REFUSE:
			return visitor.refuse_reply
		_:
			return visitor.talk_out_success_reply
