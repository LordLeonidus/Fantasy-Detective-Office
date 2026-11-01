class_name WindowLightsSchedule
extends Resource
## Сколько окон в домах за окном горит в разное время суток. Кривая задаётся на сутки:
## по оси X — доля суток (0 — полночь, 1 — следующая полночь), по оси Y — доля горящих окон.

@export var lit_fraction_curve: Curve


## Доля горящих окон в минуту `minute` от полуночи.
func lit_fraction_at(minute: float) -> float:
	assert(lit_fraction_curve != null, "Не задана кривая горящих окон")
	var day_fraction: float = fposmod(minute, GameClock.MINUTES_PER_DAY) / GameClock.MINUTES_PER_DAY
	return clampf(lit_fraction_curve.sample(day_fraction), 0.0, 1.0)
