class_name ReceptionPresenter
extends Node
## Связывает приём с кабинетом: показывает посетителя, его реплики на плашке, блокнот с вопросами
## и плашку решения, передаёт действия игрока в `Reception`.

@export var visitor_view: VisitorView
@export var speech_panel: SpeechPanel
@export var notebook_panel: NotebookPanel
@export var decision_panel: DecisionPanel
## Что написано на плашке речи до первого посетителя.
@export_multiline var start_notice: String = "Утро. В коридоре ждут люди."
## Что написано утром следующих дней: номер дня и сколько ждут в коридоре.
@export_multiline var morning_notice: String = "Утро, день %d. В коридоре: %d."

var _reception: Reception
var _workday: Workday


## Начать показывать приём и блокнот.
func bind(reception: Reception, notebook: Notebook, workday: Workday) -> void:
	_reception = reception
	_workday = workday
	_workday.reception_open_changed.connect(func(_is_open: bool) -> void: _refresh_controls())
	_workday.day_started.connect(_on_day_started)
	speech_panel.bind(notebook)
	notebook_panel.bind(notebook)
	_reception.visitor_entered.connect(_on_visitor_entered)
	_reception.visitor_spoke.connect(speech_panel.show_line)
	_reception.visitor_left.connect(_on_visitor_left)
	speech_panel.phrase_clicked.connect(_reception.toggle_note)
	speech_panel.retell_requested.connect(_reception.retell)
	notebook_panel.remove_requested.connect(_reception.remove_note)
	notebook_panel.selection_changed.connect(func(_entry: NotebookEntry) -> void: _refresh_questions())
	notebook_panel.question_asked.connect(_on_question_chosen)
	decision_panel.decision_requested.connect(_reception.decide)
	decision_panel.call_next_requested.connect(_reception.call_next)
	speech_panel.show_notice(start_notice)
	_refresh_controls()


func _on_visitor_entered(visitor: VisitorDefinition) -> void:
	visitor_view.show_visitor(visitor)
	notebook_panel.open_page(visitor)
	_refresh_controls()


func _on_visitor_left(_visitor: VisitorDefinition) -> void:
	visitor_view.hide_visitor()
	_refresh_controls()


func _on_question_chosen(entry: NotebookEntry, question: QuestionTemplate) -> void:
	_reception.ask(entry, question)
	_refresh_questions()


func _on_day_started(day: int) -> void:
	speech_panel.show_notice(morning_notice % [day, _reception.get_waiting_count()])
	_refresh_controls()


func _refresh_controls() -> void:
	decision_panel.show_state(_reception.has_visitor(), _reception.get_waiting_count(), _workday.is_reception_open())
	speech_panel.set_retell_available(_reception.has_visitor())
	_refresh_questions()


func _refresh_questions() -> void:
	var entry: NotebookEntry = notebook_panel.get_selected_entry()
	if entry == null:
		notebook_panel.show_questions([], [], false)
		return
	var questions: Array[QuestionTemplate] = _reception.get_questions(entry)
	var asked: Array[bool] = []
	for question: QuestionTemplate in questions:
		asked.append(_reception.was_asked(entry, question))
	notebook_panel.show_questions(questions, asked, _reception.has_visitor())
