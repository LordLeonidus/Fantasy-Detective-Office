class_name OfficeController
extends Node
## Собирает кабинет: создаёт игровые часы, блокнот, приём, дела, поручения, входящие,
## картотеку, казну и рабочий день и связывает их с показом в кабинете.

@export var time_of_day: TimeOfDayPresenter
@export var reception_presenter: ReceptionPresenter
@export var investigation_presenter: InvestigationPresenter
@export var clock_debug_panel: ClockDebugPanel
## Кто придёт, что расскажет, какие дела и отделы есть.
@export var scenario: ScenarioDefinition
@export var reception_rules: ReceptionRules
@export var investigation_rules: InvestigationRules

var _clock: GameClock
var _notebook: Notebook
var _reception: Reception
var _treasury: Treasury
var _inbox: Inbox
var _case_book: CaseBook
var _order_desk: OrderDesk
var _card_index: CardIndex
var _workday: Workday
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_clock = GameClock.new(investigation_rules.day_start_minute)
	_notebook = Notebook.new()
	_reception = Reception.new(scenario, reception_rules, _clock, _notebook)
	_treasury = Treasury.new(investigation_rules.start_money)
	_inbox = Inbox.new(scenario, _clock)
	_case_book = CaseBook.new(scenario, _clock, _treasury, _inbox)
	_order_desk = OrderDesk.new(scenario, _clock, _treasury, _case_book, _inbox)
	_card_index = CardIndex.new(scenario)
	_workday = Workday.new(_clock, investigation_rules, _reception)
	_reception.decision_made.connect(_case_book.handle_decision)

	time_of_day.reshuffle_window_lights(_rng)
	time_of_day.bind(_clock)
	reception_presenter.bind(_reception, _notebook, _workday)
	investigation_presenter.bind(_notebook, _case_book, _order_desk, _inbox, _card_index, _treasury, _workday, _reception)
	clock_debug_panel.bind(_clock)
	clock_debug_panel.window_lights_reshuffle_requested.connect(_reshuffle_window_lights)
	_workday.day_started.connect(func(_day: int) -> void: _reshuffle_window_lights())
	_case_book.deliver_due()


func _reshuffle_window_lights() -> void:
	time_of_day.reshuffle_window_lights(_rng)
