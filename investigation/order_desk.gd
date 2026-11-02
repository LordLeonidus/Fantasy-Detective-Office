class_name OrderDesk
extends RefCounted
## Поручения отделам. Поручение даётся о записи в блокноте по открытому делу, стоит серебра
## и готово через время. Готовый результат ложится во входящие от имени отдела; если он
## раскрывает дело, дело закрывается с наградой. Одно и то же поручение дважды не даётся.

signal order_placed(order: Order)
signal order_completed(order: Order)

const RESULT_TITLE_TEXT := "%s: %s — «%s»"

var _scenario: ScenarioDefinition
var _clock: GameClock
var _treasury: Treasury
var _case_book: CaseBook
var _inbox: Inbox
## Все данные поручения, и выполненные, и в работе.
var _orders: Array[Order] = []
var _pending: Array[Order] = []


func _init(scenario: ScenarioDefinition, clock: GameClock, treasury: Treasury, case_book: CaseBook, inbox: Inbox) -> void:
	_scenario = scenario
	_clock = clock
	_treasury = treasury
	_case_book = case_book
	_inbox = inbox
	# Методы, а не лямбды: лямбда с `self` держала бы этот объект и замкнула цикл ссылок с часами.
	_clock.time_advanced.connect(_on_clock_changed)
	_clock.time_set.connect(_on_clock_changed)


## Какие поручения можно предложить о факте по делу.
func get_offers(fact: FactDefinition, case_file: CaseFile) -> Array[OrderOffer]:
	var offers: Array[OrderOffer] = []
	for department: DepartmentDefinition in _scenario.departments:
		for action: DepartmentAction in department.actions:
			if not action.fits(fact.kind):
				continue
			var state: OrderOffer.State = OrderOffer.State.AVAILABLE
			if _find_order(action, fact, case_file) != null:
				state = OrderOffer.State.PLACED
			elif not _treasury.can_afford(action.cost):
				state = OrderOffer.State.TOO_EXPENSIVE
			offers.append(OrderOffer.new(department, action, state))
	return offers


## Дать поручение. Дело должно быть открыто, серебра хватать, а такого поручения ещё не быть.
func place(department: DepartmentDefinition, action: DepartmentAction, fact: FactDefinition, case_file: CaseFile) -> void:
	assert(case_file.is_open(), "Поручение можно дать только по открытому делу")
	assert(_find_order(action, fact, case_file) == null, "Такое поручение уже дано")
	_treasury.spend(action.cost)
	var order: Order = Order.new(department, action, fact, case_file, _clock.get_absolute_minute() + action.duration_minutes)
	_orders.append(order)
	_pending.append(order)
	order_placed.emit(order)


## Сколько поручений ещё в работе.
func get_pending_count() -> int:
	return _pending.size()


func _find_order(action: DepartmentAction, fact: FactDefinition, case_file: CaseFile) -> Order:
	for order: Order in _orders:
		if order.is_same(action, fact, case_file):
			return order
	return null


func _on_clock_changed(_minute: int) -> void:
	var now: int = _clock.get_absolute_minute()
	for order: Order in _pending.duplicate():
		if order.ready_minute <= now:
			_pending.erase(order)
			_complete(order)


func _complete(order: Order) -> void:
	var outcome: OrderOutcome = _scenario.find_outcome(order.action, order.fact, order.case_file.definition)
	var result: String = outcome.result if outcome != null else order.action.fallback_result
	var title: String = RESULT_TITLE_TEXT % [order.department.display_name, order.action.text, order.fact.note]
	_inbox.add(title, order.department, result)
	order_completed.emit(order)
	if outcome != null and outcome.solves_case:
		_case_book.solve(order.case_file)
