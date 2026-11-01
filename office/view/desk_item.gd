class_name DeskItem
extends Button
## Предмет на столе. Клик открывает его крупным планом в `CloseupPanel`. Пока заглушка:
## у предмета есть название и текст-описание, настоящий спрайт и начинка появятся позже.

@export var closeup: CloseupPanel
@export var title: String
@export_multiline var placeholder_body: String


func _ready() -> void:
	text = title
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	closeup.toggle(self, title, placeholder_body)
