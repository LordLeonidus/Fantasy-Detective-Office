class_name OrderOffer
extends RefCounted
## Поручение, которое можно предложить игроку о записи по делу, и можно ли дать его сейчас.

enum State { AVAILABLE, PLACED, TOO_EXPENSIVE }

var department: DepartmentDefinition
var action: DepartmentAction
var state: State


func _init(offer_department: DepartmentDefinition, offer_action: DepartmentAction, offer_state: State) -> void:
	department = offer_department
	action = offer_action
	state = offer_state
