class_name NotebookPanel
extends PanelContainer
## Раскрытый блокнот на столе: записи дознавателя, у каждого источника своя страница
## (посетитель, отдел, картотека, начальство). Клик по записи выбирает её, и под страницей
## появляются вопросы, которые о ней можно задать, и поручения отделам о ней по выбранному делу.
## Выбор сохраняется при листании, поэтому запись со страницы одного человека можно предъявить
## другому. Пока запись не закреплена, рядом с ней есть крестик — убрать её; записи со слов
## посетителя закрепляются, когда он уходит.

## Выбрана запись или выбор снят (`null`).
signal selection_changed(entry: NotebookEntry)
## Игрок задал вопрос о выбранной записи.
signal question_asked(entry: NotebookEntry, question: QuestionTemplate)
## Игрок убирает запись из блокнота.
signal remove_requested(entry: NotebookEntry)
## Игрок выбрал другое дело для поручений.
signal order_case_changed(case_file: CaseFile)
## Игрок дал поручение о выбранной записи по выбранному делу.
signal order_requested(entry: NotebookEntry, offer: OrderOffer, case_file: CaseFile)

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
const ORDER_TEXT := "%s: %s — %s"
const ORDER_PRICE_TEXT := "%d сер., %s"
const ORDER_FREE_TEXT := "бесплатно, %s"
const ORDER_PLACED_SUFFIX := " (дано)"
const ORDER_EXPENSIVE_SUFFIX := " (не хватает серебра)"
const NO_ENTRY_ORDER_TEXT := "Выберите запись, чтобы дать о ней поручение."
const NO_CASES_TEXT := "Нет открытых дел — поручать не по чему."
const NO_OFFERS_TEXT := "Об этой записи отделам поручить нечего."


## Страница блокнота: со слов какого человека записи.
class Page:
	var source: SpeakerDefinition

	func _init(page_source: SpeakerDefinition) -> void:
		source = page_source


@export var selected_color: Color = Color(0.96, 0.78, 0.42)
@export var muted_color: Color = Color(0.6, 0.6, 0.6)

var _notebook: Notebook
var _pages: Array[Page] = []
var _current_page_index: int = -1
var _selected: NotebookEntry
## Открытые дела в списке выбора дела для поручений, по порядку пунктов.
var _order_cases: Array[CaseFile] = []

@onready var _page_title: Label = %PageTitle
@onready var _previous_page_button: Button = %PreviousPageButton
@onready var _next_page_button: Button = %NextPageButton
@onready var _page_text: RichTextLabel = %PageText
@onready var _selection_label: Label = %SelectionLabel
@onready var _question_list: VBoxContainer = %QuestionList
@onready var _order_case_option: OptionButton = %OrderCaseOption
@onready var _order_hint_label: Label = %OrderHintLabel
@onready var _order_list: VBoxContainer = %OrderList


func _ready() -> void:
	_page_text.bbcode_enabled = true
	_page_text.meta_underlined = false
	_page_text.meta_clicked.connect(_on_meta_clicked)
	_previous_page_button.pressed.connect(_turn_page.bind(-1))
	_next_page_button.pressed.connect(_turn_page.bind(1))
	_order_case_option.item_selected.connect(func(_index: int) -> void: order_case_changed.emit(get_order_case()))
	_refresh_page()
	show_questions([], [], false)
	show_orders([], [], null)


func bind(notebook: Notebook) -> void:
	_notebook = notebook
	_notebook.entry_added.connect(_on_entry_added)
	_notebook.entry_removed.connect(_on_entry_removed)
	_notebook.entries_fixed.connect(func(_source: SpeakerDefinition) -> void: _render_page())


## Выбранная запись или `null`.
func get_selected_entry() -> NotebookEntry:
	return _selected


## Открыть страницу человека, заведя её, если её ещё нет.
func open_page(source: SpeakerDefinition) -> void:
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


## Дело, выбранное для поручений, или `null`, если открытых дел нет.
func get_order_case() -> CaseFile:
	var index: int = _order_case_option.selected
	return _order_cases[index] if index >= 0 and index < _order_cases.size() else null


## Показать поручения о выбранной записи. `cases` — открытые дела для выбора, `selected_case` —
## какое из них выбрано (`offers` посчитаны по нему).
func show_orders(offers: Array[OrderOffer], cases: Array[CaseFile], selected_case: CaseFile) -> void:
	for child: Node in _order_list.get_children():
		child.queue_free()
	_order_cases = cases
	_order_case_option.clear()
	for case_file: CaseFile in cases:
		_order_case_option.add_item(case_file.definition.title)
	_order_case_option.select(cases.find(selected_case))
	_order_case_option.visible = not cases.is_empty()
	if _selected == null:
		_order_hint_label.text = NO_ENTRY_ORDER_TEXT
	elif cases.is_empty():
		_order_hint_label.text = NO_CASES_TEXT
	elif offers.is_empty():
		_order_hint_label.text = NO_OFFERS_TEXT
	else:
		_order_hint_label.text = ""
	_order_hint_label.visible = not _order_hint_label.text.is_empty()
	for offer: OrderOffer in offers:
		var button: Button = Button.new()
		button.text = _order_text(offer)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = offer.state != OrderOffer.State.AVAILABLE
		button.pressed.connect(func() -> void: order_requested.emit(_selected, offer, get_order_case()))
		_order_list.add_child(button)


func _order_text(offer: OrderOffer) -> String:
	var duration: String = GameClock.format_duration(offer.action.duration_minutes)
	var price: String = ORDER_FREE_TEXT % duration
	if offer.action.cost > 0:
		price = ORDER_PRICE_TEXT % [offer.action.cost, duration]
	var text: String = ORDER_TEXT % [offer.department.display_name, offer.action.text, price]
	match offer.state:
		OrderOffer.State.PLACED:
			text += ORDER_PLACED_SUFFIX
		OrderOffer.State.TOO_EXPENSIVE:
			text += ORDER_EXPENSIVE_SUFFIX
	return text


func _ensure_page(source: SpeakerDefinition) -> Page:
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
