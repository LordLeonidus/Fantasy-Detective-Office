class_name PersonRecord
extends Resource
## Карточка жителя в картотеке. Находится поиском по словам из текста и ключевым словам.
## В тексте смысловые фразы `[текст|id]` можно записать в блокнот (например, имя — чтобы
## дать о человеке поручение).

@export var id: StringName
@export_multiline var text: String
## Слова, по которым карточка находится, сверх слов текста: раса, ремесло, приметы.
@export var keywords: PackedStringArray = PackedStringArray()


## Подходит ли карточка под запрос. Пустой запрос подходит ко всем.
func matches(query: String) -> bool:
	var needle: String = query.strip_edges().to_lower()
	if needle.is_empty():
		return true
	if text.to_lower().contains(needle):
		return true
	for keyword: String in keywords:
		if keyword.to_lower().contains(needle):
			return true
	return false
