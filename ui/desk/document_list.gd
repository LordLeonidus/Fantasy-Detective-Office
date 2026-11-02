class_name DocumentList
extends RichTextLabel
## Список бумаг (результаты поручений, вводные, карточки картотеки) с кликабельными смысловыми
## фразами, как в речи посетителя: клик записывает фразу в блокнот, записанные выделены.

## Игрок кликнул по смысловой фразе.
signal phrase_clicked(fact: FactDefinition, source: SpeakerDefinition)

const HEADER_TEXT := "[color=#%s]%s[/color]\n"
const SEPARATOR := "\n\n"

@export var captured_color: Color = Color(0.96, 0.78, 0.42)
@export var header_color: Color = Color(0.6, 0.6, 0.6)

var _notebook: Notebook
var _headers: PackedStringArray = PackedStringArray()
var _lines: Array[SpokenLine] = []
var _empty_text: String = ""
## Факт и источник каждой фразы по идентификатору факта — чтобы узнать их по клику.
var _facts: Dictionary[StringName, FactDefinition] = {}
var _sources: Dictionary[StringName, SpeakerDefinition] = {}


func _ready() -> void:
	bbcode_enabled = true
	meta_underlined = false
	meta_clicked.connect(_on_meta_clicked)


## Начать выделять записанное в блокноте.
func bind(notebook: Notebook) -> void:
	_notebook = notebook
	_notebook.entry_added.connect(func(_entry: NotebookEntry) -> void: _render())
	_notebook.entry_removed.connect(func(_entry: NotebookEntry) -> void: _render())


## Показать бумаги: заголовок над каждой (может быть пустым) и текст. Пустой список — `empty_text`.
func show_documents(headers: PackedStringArray, lines: Array[SpokenLine], empty_text: String) -> void:
	assert(headers.size() == lines.size(), "Заголовков не столько, сколько бумаг")
	_headers = headers
	_lines = lines
	_empty_text = empty_text
	_facts.clear()
	_sources.clear()
	for line: SpokenLine in lines:
		for chunk: SpeechChunk in line.chunks:
			if chunk.is_capturable():
				_facts[chunk.fact.id] = chunk.fact
				_sources[chunk.fact.id] = line.speaker
	_render()


func _render() -> void:
	if _lines.is_empty():
		text = "[color=#%s]%s[/color]" % [header_color.to_html(false), SpeechFormatter.escape(_empty_text)]
		return
	var parts: PackedStringArray = PackedStringArray()
	for index: int in _lines.size():
		var part: String = ""
		if not _headers[index].is_empty():
			part += HEADER_TEXT % [header_color.to_html(false), SpeechFormatter.escape(_headers[index])]
		part += SpeechFormatter.to_bbcode(_lines[index], _notebook, captured_color)
		parts.append(part)
	text = SEPARATOR.join(parts)


func _on_meta_clicked(meta: Variant) -> void:
	var fact_id: StringName = StringName(str(meta))
	if _facts.has(fact_id):
		phrase_clicked.emit(_facts[fact_id], _sources[fact_id])
