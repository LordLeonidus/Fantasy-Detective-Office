class_name QuestionCatalog
extends Resource
## Все вопросы по типам фактов и вопрос, который можно задать о любой записи своего собеседника.

@export var templates: Array[QuestionTemplate] = []
## Подходит к любой записи того, кто её сказал.
@export var universal: QuestionTemplate


## Какие вопросы показать к записи о факте. `own` — запись сказал тот, кто сейчас сидит напротив.
func questions_for(fact: FactDefinition, own: bool) -> Array[QuestionTemplate]:
	var questions: Array[QuestionTemplate] = []
	var scope: QuestionTemplate.Scope = QuestionTemplate.Scope.OWN if own else QuestionTemplate.Scope.OTHERS
	for template: QuestionTemplate in templates:
		if template.fits(fact.kind, scope):
			questions.append(template)
	if own:
		questions.append_array(fact.extra_questions)
	if own and universal != null:
		questions.append(universal)
	return questions
