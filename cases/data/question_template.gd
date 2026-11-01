class_name QuestionTemplate
extends Resource
## Готовый вопрос, который можно задать о записи в блокноте. Показывается только к записям
## подходящего типа, поэтому нелогичных вопросов («кто?» ко времени) не бывает.

## Кому задаётся вопрос: тому, кто сказал запись, или кому-то другому (предъявление).
enum Scope { OWN, OTHERS }

@export var id: StringName
@export var text: String
@export var scope: Scope = Scope.OWN
## Типы фактов (`FactDefinition.Kind`), к которым вопрос подходит.
@export var kinds: PackedInt32Array = PackedInt32Array()


func fits(kind: FactDefinition.Kind, asked_scope: Scope) -> bool:
	return scope == asked_scope and kinds.has(kind)
