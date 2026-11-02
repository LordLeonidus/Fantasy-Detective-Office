class_name InvestigationRules
extends Resource
## Настройки работы отдела: рабочий день и казна на старте.

## Начало рабочего дня, минуты от полуночи.
@export var day_start_minute: int = 540
## После этой минуты посетителей больше не зовут, остаётся закончить день.
@export var day_end_minute: int = 1080
## Серебро в казне отдела в начале игры.
@export var start_money: int = 20
