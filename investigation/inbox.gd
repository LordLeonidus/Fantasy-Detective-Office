class_name Inbox
extends RefCounted
## Входящие: бумаги, пришедшие в отдел, новые сверху.

signal document_added(document: InboxDocument)
signal unread_changed(count: int)

var _scenario: ScenarioDefinition
var _clock: GameClock
var _documents: Array[InboxDocument] = []


func _init(scenario: ScenarioDefinition, clock: GameClock) -> void:
	_scenario = scenario
	_clock = clock


## Положить бумагу: заголовок и размеченный текст от имени `speaker`.
func add(title: String, speaker: SpeakerDefinition, markup: String) -> void:
	var line: SpokenLine = SpokenLine.new(speaker, SpeechParser.parse(markup, _scenario))
	var document: InboxDocument = InboxDocument.new(title, line, _clock.get_day(), _clock.get_minute())
	_documents.push_front(document)
	document_added.emit(document)
	unread_changed.emit(get_unread_count())


## Бумаги, новые сверху.
func get_documents() -> Array[InboxDocument]:
	return _documents.duplicate()


func get_unread_count() -> int:
	var count: int = 0
	for document: InboxDocument in _documents:
		if not document.is_read:
			count += 1
	return count


func mark_all_read() -> void:
	if get_unread_count() == 0:
		return
	for document: InboxDocument in _documents:
		document.is_read = true
	unread_changed.emit(0)
