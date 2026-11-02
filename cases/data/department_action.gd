class_name DepartmentAction
extends Resource
## Что можно поручить отделу о записи в блокноте: анализ улики, зелье, задержание.
## Поручение даётся по открытому делу, стоит серебра и выполняется через время.

@export var id: StringName
## Как поручение называется на кнопке.
@export var text: String
## Типы фактов (`FactDefinition.Kind`), о которых можно дать такое поручение.
@export var kinds: PackedInt32Array = PackedInt32Array()
## Цена в серебре.
@export var cost: int = 0
## Через сколько игровых минут готов результат.
@export var duration_minutes: int = 60
## Результат, если для этой записи по этому делу ничего особого нет.
@export_multiline var fallback_result: String


func fits(kind: FactDefinition.Kind) -> bool:
	return kinds.has(kind)
