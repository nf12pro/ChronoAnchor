extends CharacterBody2D

#region Settings & Speed Variables
@export var max_speed: float = 200
@export var acceleration: float = 1200
@export var friction: float = 1500
@export var snap_tap: bool = true
#endregion

#region Snap Tap Trackers
var left_time: float = 0.0
var right_time: float = 0.0
var up_time: float = 0.0
var down_time: float = 0.0
#endregion

func _physics_process(delta: float) -> void:
	var current_time = Time.get_ticks_msec()
	
	if Input.is_action_just_pressed("move_left"):  left_time  = current_time
	if Input.is_action_just_pressed("move_right"): right_time = current_time
	if Input.is_action_just_pressed("move_up"):    up_time    = current_time
	if Input.is_action_just_pressed("move_down"):  down_time  = current_time

	var input_direction := Vector2.ZERO
	
	if snap_tap:
		input_direction.x = get_snap_axis("move_left", "move_right", left_time, right_time)
		input_direction.y = get_snap_axis("move_up", "move_down", up_time, down_time)
		input_direction = input_direction.normalized()
	else:
		input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var target_velocity = input_direction * max_speed
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

func get_snap_axis(negative_action: String, positive_action: String, negative_time: float, positive_time: float) -> float:
	var negative_held = Input.is_action_pressed(negative_action)
	var positive_held = Input.is_action_pressed(positive_action)
	
	if negative_held and positive_held:
		return 1.0 if positive_time > negative_time else -1.0
		
	if positive_held: return 1.0
	if negative_held: return -1.0
	return 0.0
