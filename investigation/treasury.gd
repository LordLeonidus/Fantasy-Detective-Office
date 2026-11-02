class_name Treasury
extends RefCounted
## Казна отдела в серебре: поручения отделам её тратят, раскрытые дела пополняют.

signal balance_changed(balance: int)

var _balance: int


func _init(start_balance: int) -> void:
	_balance = start_balance


func get_balance() -> int:
	return _balance


func can_afford(amount: int) -> bool:
	return amount <= _balance


func spend(amount: int) -> void:
	assert(can_afford(amount), "В казне не хватает серебра")
	if amount == 0:
		return
	_balance -= amount
	balance_changed.emit(_balance)


func earn(amount: int) -> void:
	if amount == 0:
		return
	_balance += amount
	balance_changed.emit(_balance)
