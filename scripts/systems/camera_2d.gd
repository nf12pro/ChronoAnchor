extends Camera2D

@export var max_offset: Vector2 = Vector2(20, 20)
@export var max_roll: float = 0.1 

@export var decay: float = 0.8 

var trauma: float = 0.0
var trauma_power: float = 2

@onready var noise: FastNoiseLite = $Offset.noise 
var noise_y: float = 0.0

func _ready() -> void:
	randomize()

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = max(trauma - decay * delta, 0.0)
		shake()
	else:
		offset = Vector2.ZERO
		rotation = 0.0

func shake() -> void:
	var amount = pow(trauma, trauma_power)
	noise_y += 1.0
	
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed * 2, noise_y)
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed * 3, noise_y)
