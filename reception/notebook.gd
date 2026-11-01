class_name Notebook
extends RefCounted
## Блокнот следователя: записи по фактам в порядке записи. Каждый факт записывается один раз;
## повторный клик по той же фразе убирает запись. Закреплённые записи убрать нельзя.

signal entry_added(entry: NotebookEntry)
signal entry_removed(entry: NotebookEntry)
## Записи с чьих-то слов закрепились.
signal entries_fixed(source: VisitorDefinition)

var _entries: Array[NotebookEntry] = []


## Записать фразу, если её нет, или убрать, если она уже записана и не закреплена.
func toggle(fact: FactDefinition, source: VisitorDefinition) -> void:
	if has(fact.id):
		remove(fact.id)
	else:
		add(fact, source)


func add(fact: FactDefinition, source: VisitorDefinition) -> void:
	if has(fact.id):
		return
	var entry: NotebookEntry = NotebookEntry.new(fact, source)
	_entries.append(entry)
	entry_added.emit(entry)


## Убрать запись, если она не закреплена.
func remove(fact_id: StringName) -> void:
	var entry: NotebookEntry = get_entry(fact_id)
	if entry == null or entry.is_fixed:
		return
	_entries.erase(entry)
	entry_removed.emit(entry)


## Закрепить все записи со слов человека.
func fix_entries_from(source: VisitorDefinition) -> void:
	for entry: NotebookEntry in get_entries_from(source):
		entry.is_fixed = true
	entries_fixed.emit(source)


## Запись по факту или `null`.
func get_entry(fact_id: StringName) -> NotebookEntry:
	for entry: NotebookEntry in _entries:
		if entry.fact.id == fact_id:
			return entry
	return null


func has(fact_id: StringName) -> bool:
	return get_entry(fact_id) != null


## Записи со слов человека в порядке записи.
func get_entries_from(source: VisitorDefinition) -> Array[NotebookEntry]:
	var entries: Array[NotebookEntry] = []
	for entry: NotebookEntry in _entries:
		if entry.source == source:
			entries.append(entry)
	return entries
