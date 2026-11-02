class_name InvestigationPresenter
extends Node
## Связывает расследование с кабинетом: поручения о записях в блокноте, входящие, картотеку,
## папки дел и плашку дня; фразы из бумаг записывает в блокнот.

@export var notebook_panel: NotebookPanel
@export var inbox_panel: InboxPanel
@export var inbox_item: DeskItem
@export var card_index_panel: CardIndexPanel
@export var case_folder_panel: CaseFolderPanel
@export var day_panel: DayPanel

var _notebook: Notebook
var _case_book: CaseBook
var _order_desk: OrderDesk
var _inbox: Inbox
var _treasury: Treasury
var _workday: Workday
var _reception: Reception


func bind(
	notebook: Notebook,
	case_book: CaseBook,
	order_desk: OrderDesk,
	inbox: Inbox,
	card_index: CardIndex,
	treasury: Treasury,
	workday: Workday,
	reception: Reception,
) -> void:
	_notebook = notebook
	_case_book = case_book
	_order_desk = order_desk
	_inbox = inbox
	_treasury = treasury
	_workday = workday
	_reception = reception

	inbox_panel.bind(inbox, notebook)
	card_index_panel.bind(card_index, notebook)
	case_folder_panel.bind(case_book)
	inbox_panel.phrase_clicked.connect(_notebook.toggle)
	card_index_panel.phrase_clicked.connect(_notebook.toggle)
	_inbox.unread_changed.connect(inbox_item.set_badge)
	inbox_item.set_badge(_inbox.get_unread_count())

	notebook_panel.selection_changed.connect(func(_entry: NotebookEntry) -> void: _refresh_orders(null))
	notebook_panel.order_case_changed.connect(_refresh_orders)
	notebook_panel.order_requested.connect(_on_order_requested)
	_case_book.case_opened.connect(func(_case_file: CaseFile) -> void: _refresh_orders(notebook_panel.get_order_case()))
	_case_book.case_solved.connect(func(_case_file: CaseFile) -> void: _refresh_orders(notebook_panel.get_order_case()))
	_treasury.balance_changed.connect(_on_balance_changed)
	_order_desk.order_placed.connect(func(_order: Order) -> void: _refresh_pending())
	_order_desk.order_completed.connect(func(_order: Order) -> void: _refresh_pending())

	day_panel.end_day_requested.connect(_workday.end_day)
	_workday.day_started.connect(day_panel.show_day)
	_reception.visitor_entered.connect(func(_visitor: VisitorDefinition) -> void: _refresh_end_day())
	_reception.visitor_left.connect(func(_visitor: VisitorDefinition) -> void: _refresh_end_day())

	day_panel.show_day(_workday.get_day())
	day_panel.show_money(_treasury.get_balance())
	_refresh_pending()
	_refresh_end_day()
	_refresh_orders(null)


func _on_order_requested(entry: NotebookEntry, offer: OrderOffer, case_file: CaseFile) -> void:
	_order_desk.place(offer.department, offer.action, entry.fact, case_file)
	_refresh_orders(case_file)


func _on_balance_changed(balance: int) -> void:
	day_panel.show_money(balance)
	_refresh_orders(notebook_panel.get_order_case())


## Показать поручения о выбранной записи по делу `preferred`, а если его нет среди открытых —
## по делу того, со слов кого запись, или по первому открытому.
func _refresh_orders(preferred: CaseFile) -> void:
	var entry: NotebookEntry = notebook_panel.get_selected_entry()
	var cases: Array[CaseFile] = _case_book.get_open_cases()
	var selected: CaseFile = preferred if cases.has(preferred) else _default_case(entry, cases)
	var offers: Array[OrderOffer] = []
	if entry != null and selected != null:
		offers = _order_desk.get_offers(entry.fact, selected)
	notebook_panel.show_orders(offers, cases, selected)


func _default_case(entry: NotebookEntry, cases: Array[CaseFile]) -> CaseFile:
	if cases.is_empty():
		return null
	if entry != null and entry.source is VisitorDefinition:
		var own: CaseFile = _case_book.find_case_of(entry.source as VisitorDefinition)
		if own != null and cases.has(own):
			return own
	return cases[0]


func _refresh_pending() -> void:
	day_panel.show_pending_orders(_order_desk.get_pending_count())


func _refresh_end_day() -> void:
	day_panel.set_end_day_available(_workday.can_end_day())
