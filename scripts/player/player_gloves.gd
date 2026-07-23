extends CharacterBody2D

@onready var gloves_equipment = $gloves_equipment

#region Movement
@export var max_speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1500.0
#endregion

#region Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 2000.0
#endregion

#region Soft Collision
const SoftCollision = preload("res://scripts/systems/soft_collision.gd")
var soft_collision: Area2D
@export var soft_collision_strength: float = 150.0
#endregion

#region Invincibility
@onready var damage_invincible_timer = $damage_invincible_timer
var dash_invincible: bool = false
var damage_invincible: bool = false
#endregion

#region Health
@onready var health_bar = $health_bar
@onready var health_timer = $health_timer
@export var max_health: float = 100
var health: float = 100 : set = set_health

@export var health_recover_upgrade = false
#endregion

#region Snap Tap
var left_time: float = 0.0
var right_time: float = 0.0
var up_time: float = 0.0
var down_time: float = 0.0

@export var snap_tap: bool = true
#endregion

#region Dashing
@onready var dash_timer = $dash_timer
@onready var dash_tracker = $dash_tracker

var dash_charges: int = 3
var dash_time_left: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var last_move_direction: Vector2 = Vector2.DOWN

@export var dash_amount: int = 3
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_charge_cooldown: float = 3.0

signal dash_finished
#endregion

#region Save State
@onready var save_state_tracker = $save_state_tracker
@onready var save_state_rewind_timer = $save_state_rewind_timer

@onready var save_state_effect = $save_state_effect
@onready var save_state_active_timer = $save_state_active_timer

const save_state_sprite = preload("res://scenes/player/save_state_sprite_loading.tscn")

@export var save_state_max_amount: int = 1
var save_state_placed: int = 0
var save_state_dash_charges: Array = []
var save_state_health: Array = []
var save_state_x_location: Array = []
var save_state_y_location: Array = []

var save_state_nodes: Array = []

var save_state_rewinded: bool = false
#endregion

#region Parry
@onready var parry_area = $parry_area
@onready var parry_hitbox = $parry_area/parry_hitbox

@onready var parry_timer = $parry_timer
@onready var parry_cooldown_timer = $parry_cooldown_timer

var parry_on_cooldown: bool = false
var is_parrying: bool = false
var parried_objects: Array[Node] = []
#endregion

#region Input Buffering
@export var buffer_window: float = 0.15
var dash_buffer: float = 0.0
var parry_buffer: float = 0.0
#endregion

func _ready():
	Global.weapon_used = "Gloves"
	
	health = max_health
	health_bar.init_health(health)
	health_bar.health_depleted.connect(_on_health_depleted)
	if health_recover_upgrade:
		health_timer.start()
	dash_charges = dash_amount
	dash_tracker.text = "[b]" + str(dash_charges) + "/" + str(dash_amount) + "[/b]"
	dash_timer.wait_time = dash_charge_cooldown
	
	soft_collision = SoftCollision.new()
	soft_collision.radius = 20.0 
	add_child(soft_collision)
	
	parry_area.monitoring = false
	parry_hitbox.disabled = true

func set_health(new_health: float) -> void:
	health = clamp(new_health, 0, max_health)
	if health_bar:
		health_bar.health = health

func _physics_process(delta: float) -> void:
	Global.player_global_position = self.global_position
	var current_time = Time.get_ticks_msec()
	
	if dash_buffer > 0.0: dash_buffer -= delta
	if parry_buffer > 0.0: parry_buffer -= delta
	
	if dash_buffer > 0.0 and not is_parrying and not Global.is_dashing and dash_charges > 0:
		dash_buffer = 0.0
		dash()
		
	if parry_buffer > 0.0 and not Global.is_dashing and not Global.is_attacking and not parry_on_cooldown and not is_parrying:
		parry_buffer = 0.0
		parry()
	
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	if Input.is_action_just_pressed("move_left"):  left_time  = current_time
	if Input.is_action_just_pressed("move_right"): right_time = current_time
	if Input.is_action_just_pressed("move_up"):    up_time    = current_time
	if Input.is_action_just_pressed("move_down"):  down_time  = current_time
	
	if Global.is_dashing:
		if soft_collision and (soft_collision.monitoring or soft_collision.monitorable):
			soft_collision.monitoring = false
			soft_collision.monitorable = false

		dash_time_left -= delta
		if dash_time_left <= 0.0:
			Global.is_dashing = false
			dash_finished.emit()
			dash_invincible = false
			velocity = velocity.limit_length(max_speed)
		
		var dash_base_vel = velocity
		velocity += knockback_velocity
		move_and_slide()
		velocity = dash_base_vel
		return
	
	if soft_collision and not (soft_collision.monitoring and soft_collision.monitorable):
		soft_collision.monitoring = true
		soft_collision.monitorable = true

	var input_direction := Vector2.ZERO
	if snap_tap:
		input_direction.x = get_snap_axis("move_left", "move_right", left_time, right_time)
		input_direction.y = get_snap_axis("move_up", "move_down", up_time, down_time)
		input_direction = input_direction.normalized()
	else:
		input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != Vector2.ZERO:
		last_move_direction = input_direction
		
	if Global.on_windup:
		if Global.is_dashing and gloves_equipment.heavy_gloves_attack:
			Global.on_windup = false
			Global.cancelled_attack = true
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		var target_velocity = input_direction * max_speed
		if input_direction != Vector2.ZERO:
			velocity = velocity.move_toward(target_velocity, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	if soft_collision and soft_collision.is_overlapping():
		velocity += soft_collision.get_push_vector() * soft_collision_strength

	var normal_base_vel = velocity
	velocity += knockback_velocity
	move_and_slide()
	velocity = normal_base_vel

func get_snap_axis(negative_action: String, positive_action: String, negative_time: float, positive_time: float) -> float:
	var negative_held = Input.is_action_pressed(negative_action)
	var positive_held = Input.is_action_pressed(positive_action)
	if negative_held and positive_held:
		return 1.0 if positive_time > negative_time else -1.0
	if positive_held: return 1.0
	if negative_held: return -1.0
	return 0.0

func dash() -> void:
	if Global.is_dashing or dash_charges <= 0:
		return 
	if Global.on_windup and gloves_equipment.heavy_gloves_attack:
		Global.on_windup = false
		Global.cancelled_attack = true
	Global.is_dashing = true
	dash_invincible = true
	dash_time_left = dash_duration
	dash_direction = last_move_direction.normalized()
	velocity = dash_direction * dash_speed
	dash_charges -= 1
	dash_tracker.text = "[b]" + str(dash_charges) + "/" + str(dash_amount) + "[/b]"
	if dash_timer.is_stopped():
		dash_timer.start()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		dash_buffer = buffer_window
	if event.is_action_pressed("parry"):
		parry_buffer = buffer_window
		
	if event.is_action_pressed("place_save_state") and save_state_placed < save_state_max_amount:
		place_save_state()
	if event.is_action_pressed("rewind_to_save_state") and save_state_placed > 0:
		save_state_rewinded = true
		rewind_to_save_state()

func place_save_state() -> void:
	save_state_rewind_timer.start()
	save_state_placed += 1
	save_state_dash_charges.append(dash_charges)
	save_state_health.append(health)
	save_state_x_location.append(global_position.x)
	save_state_y_location.append(global_position.y)
	
	save_state_tracker.text = "[b]" + str(save_state_max_amount - save_state_placed) + "/" + str(save_state_max_amount) + "[/b]"
	
	var save_state_sprite_loaded = save_state_sprite.instantiate()
	save_state_sprite_loaded.global_position.x = global_position.x 
	save_state_sprite_loaded.global_position.y = global_position.y
	get_parent().add_child(save_state_sprite_loaded)
	save_state_nodes.append(save_state_sprite_loaded)

func rewind_to_save_state() -> void:
	save_state_effect.visible = true
	
	save_state_active_timer.start()
	await save_state_active_timer.timeout
	
	save_state_effect.visible = false
	
	dash_charges = save_state_dash_charges[0]
	health = save_state_health[0]
	
	global_position.x = save_state_x_location[0]
	global_position.y = save_state_y_location[0]
	
	var active_sprite = save_state_nodes[0]
	if is_instance_valid(active_sprite):
		active_sprite.queue_free()
	
	save_state_dash_charges.remove_at(0)
	save_state_health.remove_at(0)
	save_state_x_location.remove_at(0)
	save_state_y_location.remove_at(0)
	save_state_nodes.remove_at(0)
	
	save_state_tracker.text = "[b]" + str(save_state_max_amount - save_state_placed) + "/" + str(save_state_max_amount) + "[/b]"
	dash_tracker.text = "[b]" + str(dash_charges) + "/" + str(dash_amount) + "[/b]"

func take_damage(damage: float, knockback_force: Vector2 = Vector2.ZERO) -> void:
	health -= damage
	knockback_velocity = knockback_force

func parry() -> void:
	is_parrying = true
	parry_on_cooldown = true
	parried_objects.clear()
	
	parry_area.monitoring = true
	parry_hitbox.disabled = false
	
	parry_timer.start()
	call_deferred("_check_initial_overlaps")

func _check_initial_overlaps() -> void:
	await get_tree().physics_frame
	if not parry_area.monitoring:
		return
	for area in parry_area.get_overlapping_areas():
		_on_parry_area_area_entered(area)

func _on_parry_area_area_entered(area: Area2D) -> void:
	if area in parried_objects:
		return
	if not area.has_method("parried"):
		return
	
	parried_objects.append(area)
	area.parried()

func _on_health_depleted() -> void:
	print("Player died")

func _on_health_timer_timeout() -> void:
	health += 1

func _on_dash_timer_timeout() -> void:
	dash_charges = min(dash_charges + 1, dash_amount)
	dash_tracker.text = "[b]" + str(dash_charges) + "/" + str(dash_amount) + "[/b]"
	if dash_charges < dash_amount:
		dash_timer.start()

func _on_damage_invincible_timer_timeout() -> void:
	damage_invincible = false

func _on_parry_timer_timeout() -> void:
	parry_area.monitoring = false
	parry_hitbox.disabled = true
	is_parrying = false
	parry_cooldown_timer.start()

func _on_parry_cooldown_timer_timeout() -> void:
	parry_on_cooldown = false

func _on_save_state_rewind_timer_timeout() -> void:
	if save_state_rewinded:
		save_state_rewinded = false
		return
	rewind_to_save_state()
