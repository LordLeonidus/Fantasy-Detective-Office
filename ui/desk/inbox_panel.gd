class_name InboxPanel
extends CloseupView
## Входящие крупным планом: бумаги, новые сверху. Открытие помечает всё прочитанным.
## Фразы в бумагах можно записать в блокнот.

signal phrase_clicked(fact: FactDefinition, source: SpeakerDefinition)

const HEADER_TEXT := "День %d, %s — %s"
const EMPTY_TEXT := "Входящих нет. Результаты поручений и дела сверху появятся здесь."

var _inbox: Inbox

@onready var _documents: DocumentList = %Documents


func _ready() -> void:
	super._ready()
	_documents.phrase_clicked.connect(phrase_clicked.emit)


func bind(inbox: Inbox, notebook: Notebook) -> void:
	_inbox = inbox
	_documents.bind(notebook)
	_inbox.document_added.connect(func(_document: InboxDocument) -> void: _refresh())
	_refresh()


func _on_opened() -> void:
	_inbox.mark_all_read()


func _refresh() -> void:
	var headers: PackedStringArray = PackedStringArray()
	var lines: Array[SpokenLine] = []
	for document: InboxDocument in _inbox.get_documents():
		headers.append(HEADER_TEXT % [document.day, GameClock.format(document.minute), document.title])
		lines.append(document.line)
	_documents.show_documents(headers, lines, EMPTY_TEXT)
	if visible:
		_inbox.mark_all_read()
