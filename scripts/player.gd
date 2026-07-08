extends CharacterBody2D

#region Movement
@export var max_speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1500.0
@export var dash_amount: int = 3
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_charge_cooldown: float = 1.0
#endregion

#region Invincibility
var invincibility: bool = false

#region Health
@onready var health_bar = $canvas_layer/health_bar
@onready var health_timer = $health_timer
@export var max_health: float = 100
var health: float = 100 : set = set_health
#endregion

#region Snap Taping
var left_time: float = 0.0
var right_time: float = 0.0
var up_time: float = 0.0
var down_time: float = 0.0
@export var snap_tap: bool = true
#endregion

#region Upgrades
@export var health_recover_upgrade = false
#endregion

#region Dash
@onready var dash_timer = $dash_timer
var dash_charges: int = 3
var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var last_move_direction: Vector2 = Vector2.DOWN
#endregion

func _ready():
	health = max_health
	health_bar.init_health(health)
	health_bar.health_depleted.connect(_on_health_depleted)
	if health_recover_upgrade:
		health_timer.start()
	dash_charges = dash_amount
	dash_timer.wait_time = dash_charge_cooldown
	dash_timer.one_shot = true

func set_health(new_health: float) -> void:
	health = clamp(new_health, 0, max_health)
	if health_bar:
		health_bar.health = health

func _physics_process(delta: float) -> void:
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0.0:
			is_dashing = false
			velocity = velocity.limit_length(max_speed)
		move_and_slide()
		return
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
	if input_direction != Vector2.ZERO:
		last_move_direction = input_direction
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

func dash():
	if is_dashing or dash_charges <= 0:
		return
	invincibility = true
	is_dashing = true
	dash_time_left = dash_duration
	dash_direction = last_move_direction.normalized()
	velocity = dash_direction * dash_speed
	dash_charges -= 1
	if dash_timer.is_stopped():
		dash_timer.start()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("take_damage_test"):
		if not invincibility:
			health -= 20
	if event.is_action_pressed("dash"):
		dash()

func _on_health_depleted() -> void:
	print("Player died")

func _on_health_timer_timeout() -> void:
	health += 1

func _on_dash_timer_timeout() -> void:
	dash_charges = min(dash_charges + 1, dash_amount)
	if dash_charges < dash_amount:
		dash_timer.start()
