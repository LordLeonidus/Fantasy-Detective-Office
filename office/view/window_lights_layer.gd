class_name WindowLightsLayer
extends TextureRect
## Слой горящих окон в домах за окном кабинета. Показывает заданную долю горящих окон
## через шейдер `window_lights.gdshader`; какие окна горят и в каком порядке загораются,
## задаёт зерно узора. Узлу нужен `ShaderMaterial` с этим шейдером и текстурами огней.

const LIT_FRACTION_PARAM := &"lit_fraction"
const PATTERN_SEED_PARAM := &"pattern_seed"
## Зерно берётся из этого диапазона: шейдер умножает его, поэтому крупные значения не нужны.
const MAX_PATTERN_SEED := 1000.0

var _material: ShaderMaterial


func _ready() -> void:
	_material = material as ShaderMaterial
	assert(_material != null, "%s: нужен ShaderMaterial с window_lights.gdshader" % name)


## Показать долю горящих окон.
func show_lit_fraction(fraction: float) -> void:
	_material.set_shader_parameter(LIT_FRACTION_PARAM, fraction)


## Выбрать новый случайный узор: другие окна загорятся в другом порядке.
func reshuffle(rng: RandomNumberGenerator) -> void:
	_material.set_shader_parameter(PATTERN_SEED_PARAM, rng.randf_range(0.0, MAX_PATTERN_SEED))
