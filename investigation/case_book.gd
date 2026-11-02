class_name CaseBook
extends RefCounted
## Дела отдела. Принятое заявление заводит дело посетителя. Дела сверху приходят утром своего
## дня готовыми, их вводная ложится во входящие. Если заявление не принять, а у его дела есть
## продолжение, через несколько дней оно приходит сверху. Раскрытое дело приносит награду.

signal case_opened(case_file: CaseFile)
signal case_solved(case_file: CaseFile)

const ABOVE_TITLE_TEXT := "Новое дело: %s"

var _scenario: ScenarioDefinition
var _clock: GameClock
var _treasury: Treasury
var _inbox: Inbox
var _cases: Array[CaseFile] = []
## Дела сверху, которые ещё не пришли.
var _scheduled: Array[ScheduledCase] = []


func _init(scenario: ScenarioDefinition, clock: GameClock, treasury: Treasury, inbox: Inbox) -> void:
	_scenario = scenario
	_clock = clock
	_treasury = treasury
	_inbox = inbox
	_scheduled.append_array(_scenario.cases_from_above)
	_clock.day_started.connect(_deliver_scheduled)


## Принести дела сверху, которым пора прийти. Вызывается и в начале игры — для дел первого дня.
func deliver_due() -> void:
	_deliver_scheduled(_clock.get_day())


## Все дела в порядке заведения.
func get_cases() -> Array[CaseFile]:
	return _cases.duplicate()


func get_open_cases() -> Array[CaseFile]:
	var open: Array[CaseFile] = []
	for case_file: CaseFile in _cases:
		if case_file.is_open():
			open.append(case_file)
	return open


## Дело посетителя или `null`, если его заявление не принято или ни к чему не ведёт.
func find_case_of(visitor: VisitorDefinition) -> CaseFile:
	for case_file: CaseFile in _cases:
		if case_file.visitor == visitor:
			return case_file
	return null


## Решение по заявлению: принятое заводит дело, отказ запускает продолжение, если оно есть.
func handle_decision(visitor: VisitorDefinition, decision: Reception.Decision, succeeded: bool) -> void:
	var definition: CaseDefinition = visitor.case_definition
	if not succeeded or definition == null:
		return
	if decision == Reception.Decision.ACCEPT:
		_open(definition, visitor)
	elif definition.escalation != null:
		_scheduled.append(ScheduledCase.create(definition.escalation, _clock.get_day() + definition.escalation_delay_days))


## Раскрыть дело и получить награду.
func solve(case_file: CaseFile) -> void:
	if not case_file.is_open():
		return
	case_file.status = CaseFile.Status.SOLVED
	_treasury.earn(case_file.definition.reward)
	case_solved.emit(case_file)


func _open(definition: CaseDefinition, visitor: VisitorDefinition) -> CaseFile:
	var case_file: CaseFile = CaseFile.new(definition, visitor, _clock.get_day())
	_cases.append(case_file)
	case_opened.emit(case_file)
	return case_file


func _deliver_scheduled(day: int) -> void:
	for scheduled: ScheduledCase in _scheduled.duplicate():
		if scheduled.day > day:
			continue
		_scheduled.erase(scheduled)
		var definition: CaseDefinition = scheduled.case_definition
		_open(definition, null)
		_inbox.add(ABOVE_TITLE_TEXT % definition.title, _scenario.command_speaker, definition.briefing)
