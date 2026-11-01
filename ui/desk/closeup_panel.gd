class_name CloseupPanel
extends PanelContainer
## Крупный план предмета со стола. Одновременно открыт один предмет; закрывается крестиком,
## Esc или повторным кликом по тому же предмету. Начинку предметов добавят их собственные сцены.

signal closed

var _owner_item: Node

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.CANCEL):
		close()
		get_viewport().set_input_as_handled()


## Открыть предмет `item` или закрыть, если открыт именно он.
func toggle(item: Node, title: String, body: String) -> void:
	if visible and _owner_item == item:
		close()
		return
	_owner_item = item
	_title_label.text = title
	_body_label.text = body
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	_owner_item = null
	closed.emit()
