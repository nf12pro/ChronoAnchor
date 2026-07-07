extends CharacterBody2D

@export var original_speed: float = 200
@export var acceleration: float = 1200
@export var friction: float = 1200

var snap_trap: bool = true

func get_input(delta):
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity = input_direction * original_speed
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
@warning_ignore("unused_parameter")
func _physics_process(delta):
	get_input(delta)
	move_and_slide()
