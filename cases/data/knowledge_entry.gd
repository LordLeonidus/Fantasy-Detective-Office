class_name KnowledgeEntry
extends Resource
## Строка таблицы знаний персонажа: на этот вопрос об этом факте он отвечает этим текстом.
## В ответе можно размечать куски `[текст|id]`, за которыми стоят новые факты.

@export var fact: FactDefinition
@export var question: QuestionTemplate
@export_multiline var answer: String


func matches(asked_fact: FactDefinition, asked_question: QuestionTemplate) -> bool:
	return asked_fact.id == fact.id and asked_question.id == question.id
