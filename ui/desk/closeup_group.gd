class_name CloseupGroup
extends Node
## Следит, чтобы из крупных планов предметов со стола был открыт только один:
## открытие одного закрывает остальные.

@export var views: Array[CloseupView] = []


func _ready() -> void:
	for view: CloseupView in views:
		view.opened.connect(_on_view_opened.bind(view))


func _on_view_opened(opened_view: CloseupView) -> void:
	for view: CloseupView in views:
		if view != opened_view:
			view.close()
