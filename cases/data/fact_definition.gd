class_name FactDefinition
extends Resource
## Факт дела, который стоит за смысловой фразой в реплике. Клик по фразе записывает в блокнот
## не саму фразу, а её истолкование (`note`), к записи появляются вопросы по типу факта.

## Тип факта: от него зависит, какие вопросы о нём логично задать.
enum Kind { TIME, PLACE, PERSON, ITEM, MONEY, EVENT, SIGN, OTHER }

## Уникальный в пределах дня идентификатор; на него ссылается разметка реплик `[текст|id]`.
@export var id: StringName
@export var kind: Kind = Kind.OTHER
## Что следователь пишет в блокнот: фраза, понятная без разговора («украли вчера утром»).
@export var note: String
## Вопросы именно к этому факту, сверх вопросов по типу.
@export var extra_questions: Array[QuestionTemplate] = []
