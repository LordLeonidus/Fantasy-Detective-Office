class_name CloseupPanel
extends CloseupView
## Крупный план предмета-заглушки: название и текст, заданные в сцене.

@export var title: String
@export_multiline var body: String

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel


func _ready() -> void:
	super._ready()
	_title_label.text = title
	_body_label.text = body
