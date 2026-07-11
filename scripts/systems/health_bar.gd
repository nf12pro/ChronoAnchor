extends ProgressBar

@onready var timer: Timer = $timer
@onready var damage_bar: ProgressBar = $damage_bar

signal health_depleted

var health: float = 0 : set = set_health

var _initialized := false
var _value_tween: Tween
var _damage_tween: Tween

func init_health(setting_health: float) -> void:
	max_value = setting_health
	damage_bar.max_value = setting_health

	health = setting_health
	value = health
	damage_bar.value = health

	_initialized = true

func set_health(new_health: float) -> void:
	var previous_health = health
	health = clamp(new_health, 0, max_value)

	if not _initialized:
		return

	_tween_value_to(health)

	if health < previous_health:
		timer.start()
	else:
		_tween_damage_bar_to(health)

	if health <= 0 and previous_health > 0:
		health_depleted.emit()

func _tween_value_to(target: float) -> void:
	if _value_tween:
		_value_tween.kill()
	_value_tween = create_tween()
	_value_tween.tween_property(self, "value", target, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _tween_damage_bar_to(target: float) -> void:
	if _damage_tween:
		_damage_tween.kill()
	_damage_tween = create_tween()
	_damage_tween.tween_property(damage_bar, "value", target, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_timer_timeout() -> void:
	_tween_damage_bar_to(health)
