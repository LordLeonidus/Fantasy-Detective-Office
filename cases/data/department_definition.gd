class_name DepartmentDefinition
extends SpeakerDefinition
## Отдел, которому можно давать поручения: алхимик, оперы. Результаты приходят во входящие
## от его имени, записи из них ложатся на его страницу блокнота.

@export var actions: Array[DepartmentAction] = []
