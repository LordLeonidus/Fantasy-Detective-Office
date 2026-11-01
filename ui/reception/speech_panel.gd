class_name SpeechPanel
extends PanelContainer
## Плашка с последней репликой посетителя поверх нижней части посетителя, как субтитры:
## новая реплика заменяет прошлую. Клик по смысловой фразе записывает её в блокнот,
## повторный клик убирает запись. Записанные фразы подчёркнуты и выделены цветом.
## Кнопка «Расскажите с начала» возвращает на плашку первый рассказ посетителя.

## Игрок кликнул по смысловой фразе.
signal phrase_clicked(fact: FactDefinition, speaker: VisitorDefinition)
## Игрок просит рассказать всё с начала.
signal retell_requested

@export var captured_color: Color = Color(0.96, 0.78, 0.42)

var _notebook: Notebook
var _line: SpokenLine
## Факты фраз показанной реплики по идентификатору — чтобы узнать факт по клику.
var _facts: Dictionary[StringName, FactDefinition] = {}

@onready var _speaker_label: Label = %SpeakerLabel
@onready var _speech_text: RichTextLabel = %SpeechText
@onready var _retell_button: Button = %RetellButton


func _ready() -> void:
	_speech_text.bbcode_enabled = true
	_speech_text.meta_underlined = false
	_speech_text.meta_clicked.connect(_on_meta_clicked)
	_retell_button.pressed.connect(retell_requested.emit)


## Начать показывать записанное в блокноте.
func bind(notebook: Notebook) -> void:
	_notebook = notebook
	_notebook.entry_added.connect(func(_entry: NotebookEntry) -> void: _render())
	_notebook.entry_removed.connect(func(_entry: NotebookEntry) -> void: _render())


## Можно ли сейчас попросить рассказать с начала.
func set_retell_available(available: bool) -> void:
	_retell_button.disabled = not available


## Показать реплику вместо прошлой.
func show_line(line: SpokenLine) -> void:
	_line = line
	_facts.clear()
	for chunk: SpeechChunk in line.chunks:
		if chunk.is_capturable():
			_facts[chunk.fact.id] = chunk.fact
	_speaker_label.text = line.speaker.display_name
	_speaker_label.visible = true
	_render()


## Показать служебный текст без говорящего.
func show_notice(text: String) -> void:
	_line = null
	_facts.clear()
	_speaker_label.visible = false
	_speech_text.text = text


func _render() -> void:
	if _line != null:
		_speech_text.text = SpeechFormatter.to_bbcode(_line, _notebook, captured_color)


func _on_meta_clicked(meta: Variant) -> void:
	var fact: FactDefinition = _facts.get(StringName(str(meta)))
	if fact != null:
		phrase_clicked.emit(fact, _line.speaker)
