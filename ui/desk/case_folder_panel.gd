class_name CaseFolderPanel
extends CloseupView
## Папки дел крупным планом: все заведённые дела — откуда, о чём, награда, раскрыто ли.

const EMPTY_TEXT := "Дел нет. Принятое заявление заводит дело, дела сверху приходят утром."
const CASE_TEXT := "[b]%s[/b] — %s\n[color=#%s]%s · день %d · награда %d сер.[/color]\n%s"
const OPEN_TEXT := "открыто"
const SOLVED_TEXT := "раскрыто"
const FROM_ABOVE_TEXT := "сверху"
const FROM_VISITOR_TEXT := "заявление: %s"

@export var solved_color: Color = Color(0.55, 0.8, 0.5)
@export var details_color: Color = Color(0.6, 0.6, 0.6)

var _case_book: CaseBook

@onready var _case_text: RichTextLabel = %CaseText


func bind(case_book: CaseBook) -> void:
	_case_book = case_book
	_case_book.case_opened.connect(func(_case_file: CaseFile) -> void: _refresh())
	_case_book.case_solved.connect(func(_case_file: CaseFile) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	var cases: Array[CaseFile] = _case_book.get_cases()
	if cases.is_empty():
		_case_text.text = "[color=#%s]%s[/color]" % [details_color.to_html(false), EMPTY_TEXT]
		return
	var parts: PackedStringArray = PackedStringArray()
	for case_file: CaseFile in cases:
		var status: String = OPEN_TEXT
		if not case_file.is_open():
			status = "[color=#%s]%s[/color]" % [solved_color.to_html(false), SOLVED_TEXT]
		var origin: String = FROM_ABOVE_TEXT
		if not case_file.is_from_above():
			origin = FROM_VISITOR_TEXT % case_file.visitor.display_name
		var definition: CaseDefinition = case_file.definition
		parts.append(CASE_TEXT % [
			SpeechFormatter.escape(definition.title), status, details_color.to_html(false),
			SpeechFormatter.escape(origin), case_file.opened_day, definition.reward,
			SpeechFormatter.escape(definition.summary),
		])
	_case_text.text = "\n\n".join(parts)
