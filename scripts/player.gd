extends CharacterBody2D

const original_speed = 200

func get_input():
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * original_speed

@warning_ignore("unused_parameter")
func _physics_process(delta):
	get_input()
	move_and_slide()
