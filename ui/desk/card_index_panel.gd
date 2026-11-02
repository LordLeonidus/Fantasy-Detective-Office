class_name CardIndexPanel
extends CloseupView
## Картотека крупным планом: строка поиска и найденные карточки. Фразы в карточках
## (например, имя) можно записать в блокнот, чтобы дать о человеке поручение.

signal phrase_clicked(fact: FactDefinition, source: SpeakerDefinition)

const EMPTY_QUERY_TEXT := "Введите имя, примету, ремесло или улицу."
const NOTHING_FOUND_TEXT := "Ничего не найдено."

var _card_index: CardIndex

@onready var _search_edit: LineEdit = %SearchEdit
@onready var _results: DocumentList = %Results


func _ready() -> void:
	super._ready()
	_search_edit.text_changed.connect(func(_query: String) -> void: _refresh())
	_results.phrase_clicked.connect(phrase_clicked.emit)


func bind(card_index: CardIndex, notebook: Notebook) -> void:
	_card_index = card_index
	_results.bind(notebook)
	_refresh()


func _on_opened() -> void:
	_search_edit.grab_focus()


func _refresh() -> void:
	var query: String = _search_edit.text
	var lines: Array[SpokenLine] = _card_index.search(query)
	var headers: PackedStringArray = PackedStringArray()
	headers.resize(lines.size())
	var empty_text: String = EMPTY_QUERY_TEXT if query.strip_edges().is_empty() else NOTHING_FOUND_TEXT
	_results.show_documents(headers, lines, empty_text)
