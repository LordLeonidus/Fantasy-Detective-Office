class_name NotebookPanel
extends PanelContainer
## Раскрытый блокнот на столе: записи следователя, у каждого человека своя страница.
## Клик по записи выбирает её, и под страницей появляются вопросы, которые о ней можно задать.
## Выбор сохраняется при листании, поэтому запись со страницы одного человека можно предъявить
## другому. Пока человек сидит напротив, рядом с записями с его слов есть крестик — убрать запись;
## когда он уходит, записи закрепляются и крестики пропадают.

## Выбрана запись или выбор снят (`null`).
signal selection_changed(entry: NotebookEntry)
## Игрок задал вопрос о выбранной записи.
signal question_asked(entry: NotebookEntry, question: QuestionTemplate)
## Игрок убирает запись из блокнота.
signal remove_requested(entry: NotebookEntry)

const PAGE_TITLE_TEXT := "%s  (%d/%d)"
const EMPTY_TITLE_TEXT := "Блокнот пуст"
const EMPTY_PAGE_TEXT := "Ничего не записано. Кликните по фразе в речи, чтобы записать её."
const ENTRY_TEXT := "• [url=%s%s]%s[/url]"
const REMOVE_TEXT := "   [url=%s%s][color=#%s]✕[/color][/url]"
const SELECT_META_PREFIX := "select:"
const REMOVE_META_PREFIX := "remove:"
const NO_SELECTION_TEXT := "Выберите запись, чтобы спросить о ней."
const SELECTION_TEXT := "«%s» — со слов: %s"
const NOBODY_TO_ASK_TEXT := "Спросить некого."


## Страница блокнота: со слов какого человека записи.
class Page:
	var source: VisitorDefinition

	func _init(page_source: VisitorDefinition) -> void:
		source = page_source


@export var selected_color: Color = Color(0.96, 0.78, 0.42)
@export var muted_color: Color = Color(0.6, 0.6, 0.6)

var _notebook: Notebook
var _pages: Array[Page] = []
var _current_page_index: int = -1
var _selected: NotebookEntry

@onready var _page_title: Label = %PageTitle
@onready var _previous_page_button: Button = %PreviousPageButton
@onready var _next_page_button: Button = %NextPageButton
@onready var _page_text: RichTextLabel = %PageText
@onready var _selection_label: Label = %SelectionLabel
@onready var _question_list: VBoxContainer = %QuestionList


func _ready() -> void:
	_page_text.bbcode_enabled = true
	_page_text.meta_underlined = false
	_page_text.meta_clicked.connect(_on_meta_clicked)
	_previous_page_button.pressed.connect(_turn_page.bind(-1))
	_next_page_button.pressed.connect(_turn_page.bind(1))
	_refresh_page()
	show_questions([], [], false)


func bind(notebook: Notebook) -> void:
	_notebook = notebook
	_notebook.entry_added.connect(_on_entry_added)
	_notebook.entry_removed.connect(_on_entry_removed)
	_notebook.entries_fixed.connect(func(_source: VisitorDefinition) -> void: _render_page())


## Выбранная запись или `null`.
func get_selected_entry() -> NotebookEntry:
	return _selected


## Открыть страницу человека, заведя её, если её ещё нет.
func open_page(source: VisitorDefinition) -> void:
	_current_page_index = _pages.find(_ensure_page(source))
	_refresh_page()


## Показать вопросы о выбранной записи. `asked` — какие уже заданы этому человеку.
func show_questions(questions: Array[QuestionTemplate], asked: Array[bool], can_ask: bool) -> void:
	for child: Node in _question_list.get_children():
		child.queue_free()
	if _selected == null:
		_selection_label.text = NO_SELECTION_TEXT
		return
	_selection_label.text = SELECTION_TEXT % [_selected.get_text(), _selected.source.display_name]
	if not can_ask:
		_selection_label.text += "\n" + NOBODY_TO_ASK_TEXT
		return
	for index: int in questions.size():
		var button: Button = Button.new()
		button.text = questions[index].text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = asked[index]
		button.pressed.connect(_on_question_pressed.bind(questions[index]))
		_question_list.add_child(button)


func _ensure_page(source: VisitorDefinition) -> Page:
	for page: Page in _pages:
		if page.source == source:
			return page
	var page: Page = Page.new(source)
	_pages.append(page)
	if _current_page_index < 0:
		_current_page_index = 0
	return page


func _turn_page(step: int) -> void:
	_current_page_index = clampi(_current_page_index + step, 0, _pages.size() - 1)
	_refresh_page()


func _refresh_page() -> void:
	if _pages.is_empty():
		_page_title.text = EMPTY_TITLE_TEXT
	else:
		var page: Page = _pages[_current_page_index]
		_page_title.text = PAGE_TITLE_TEXT % [page.source.display_name, _current_page_index + 1, _pages.size()]
	_previous_page_button.disabled = _current_page_index <= 0
	_next_page_button.disabled = _current_page_index >= _pages.size() - 1
	_render_page()


func _render_page() -> void:
	if _pages.is_empty() or _notebook == null:
		_page_text.text = ""
		return
	var entries: Array[NotebookEntry] = _notebook.get_entries_from(_pages[_current_page_index].source)
	if entries.is_empty():
		_page_text.text = "[color=#%s]%s[/color]" % [muted_color.to_html(false), EMPTY_PAGE_TEXT]
		return
	var lines: PackedStringArray = PackedStringArray()
	for entry: NotebookEntry in entries:
		var text: String = SpeechFormatter.escape(entry.get_text())
		if entry == _selected:
			text = "[color=#%s]%s[/color]" % [selected_color.to_html(false), text]
		var line: String = ENTRY_TEXT % [SELECT_META_PREFIX, entry.fact.id, text]
		if not entry.is_fixed:
			line += REMOVE_TEXT % [REMOVE_META_PREFIX, entry.fact.id, muted_color.to_html(false)]
		lines.append(line)
	_page_text.text = "\n".join(lines)


func _select(entry: NotebookEntry) -> void:
	_selected = entry
	_render_page()
	selection_changed.emit(_selected)


func _on_entry_added(entry: NotebookEntry) -> void:
	open_page(entry.source)


func _on_entry_removed(entry: NotebookEntry) -> void:
	if entry == _selected:
		_select(null)
	else:
		_render_page()


func _on_meta_clicked(meta: Variant) -> void:
	var action: String = str(meta)
	if action.begins_with(REMOVE_META_PREFIX):
		var removed: NotebookEntry = _notebook.get_entry(StringName(action.trim_prefix(REMOVE_META_PREFIX)))
		if removed != null:
			remove_requested.emit(removed)
		return
	var entry: NotebookEntry = _notebook.get_entry(StringName(action.trim_prefix(SELECT_META_PREFIX)))
	_select(null if entry == _selected else entry)


func _on_question_pressed(question: QuestionTemplate) -> void:
	question_asked.emit(_selected, question)
