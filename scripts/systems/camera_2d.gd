extends Camera2D

@export var max_offset: Vector2 = Vector2(50, 50)  

var trauma: float = 0.0  
var trauma_power: int = 2  
var current_decay: float = 0.0

func _ready() -> void:
	Global.screenshake_requested.connect(_add_trauma)

func _add_trauma(amount: float, duration: float) -> void:
	trauma = min(trauma + amount, 1.0)
	
	if duration > 0.0:
		current_decay = trauma / duration
	else:
		current_decay = 10.0

func _process(delta: float) -> void:
	if trauma > 0:
		trauma = max(trauma - current_decay * delta, 0.0)
		_apply_shake()
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO

func _apply_shake() -> void:
	var amount = pow(trauma, trauma_power)
	
	offset.x = max_offset.x * amount * randf_range(-1.0, 1.0)
	offset.y = max_offset.y * amount * randf_range(-1.0, 1.0)
