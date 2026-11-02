class_name CloseupView
extends PanelContainer
## Крупный план предмета со стола. Открывается кликом по предмету (`DeskItem`), закрывается
## крестиком, Esc или повторным кликом. Сцена наследника должна содержать кнопку `%CloseButton`.
## Что одновременно открыт один крупный план, следит `CloseupGroup`.

signal opened
signal closed

@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.CANCEL):
		close()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	if visible:
		return
	visible = true
	_on_opened()
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Для наследников: обновить содержимое при открытии.
func _on_opened() -> void:
	pass
