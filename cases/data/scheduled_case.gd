class_name ScheduledCase
extends Resource
## Дело сверху, которое придёт в отдел утром дня `day`.

@export var case_definition: CaseDefinition
## Номер дня, считая с 1.
@export var day: int = 1


static func create(definition: CaseDefinition, arrival_day: int) -> ScheduledCase:
	var scheduled: ScheduledCase = ScheduledCase.new()
	scheduled.case_definition = definition
	scheduled.day = arrival_day
	return scheduled
