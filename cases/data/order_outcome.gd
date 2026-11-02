class_name OrderOutcome
extends Resource
## Строка таблицы результатов: поручение `action` о факте `fact` даёт этот результат.
## В результате можно размечать куски `[текст|id]`, за которыми стоят новые факты.

@export var action: DepartmentAction
@export var fact: FactDefinition
## По каким делам результат такой. Пусто — по любому.
@export var cases: Array[CaseDefinition] = []
@export_multiline var result: String
## Результат раскрывает дело, по которому дано поручение.
@export var solves_case: bool = false


func matches(asked_action: DepartmentAction, asked_fact: FactDefinition, case_definition: CaseDefinition) -> bool:
	if asked_action.id != action.id or asked_fact.id != fact.id:
		return false
	return cases.is_empty() or cases.has(case_definition)
