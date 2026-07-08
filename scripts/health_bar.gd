extends ProgressBar

@onready var timer = $timer
@onready var damage_bar = $damage_bar

var health = 0.0 : set = set_health

func set_health(new_health):
	var previous_health = health
	health = min(max_value, new_health)
	value = health
	
	if health <= 0:
		queue_free()
	
	if health < previous_health:
		timer.start()
	else:
		damage_bar.value = health

func init_health(setting_health):
	health = setting_health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health

func _on_timer_timeout() -> void:
	damage_bar.value = health
