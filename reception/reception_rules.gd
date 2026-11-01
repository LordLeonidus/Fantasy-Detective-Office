class_name ReceptionRules
extends Resource
## Настройки приёма: сколько стоят действия по времени и какие вопросы бывают.

## Сколько минут стоит вопрос посетителю.
@export var question_minutes: int = 10
## Сколько минут стоит попросить рассказать с начала.
@export var retell_minutes: int = 0
@export var question_catalog: QuestionCatalog
