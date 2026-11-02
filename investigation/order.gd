class_name Order
extends RefCounted
## Поручение отделу: что сделать, о какой записи, по какому делу и когда будет готово.

var department: DepartmentDefinition
var action: DepartmentAction
var fact: FactDefinition
var case_file: CaseFile
## Момент готовности в минутах от полуночи первого дня (`GameClock.get_absolute_minute`).
var ready_minute: int


func _init(
	order_department: DepartmentDefinition,
	order_action: DepartmentAction,
	order_fact: FactDefinition,
	order_case: CaseFile,
	order_ready_minute: int,
) -> void:
	department = order_department
	action = order_action
	fact = order_fact
	case_file = order_case
	ready_minute = order_ready_minute


## То же ли это поручение: тот же отдел делает то же по той же записи и тому же делу.
func is_same(other_action: DepartmentAction, other_fact: FactDefinition, other_case: CaseFile) -> bool:
	return action == other_action and fact.id == other_fact.id and case_file == other_case
