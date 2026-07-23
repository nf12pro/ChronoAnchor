extends CharacterBody2D

#region Movement
@export var max_speed: float = 25.0
#endregion

#region Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 600.0
@export var knockback_strength: float = 100.0
#endregion

#region Soft Collision
const SoftCollision = preload("res://scripts/systems/soft_collision.gd")
var soft_collision: Area2D
@export var soft_collision_strength: float = 120.0
#endregion

#region Invincibility
var invincibility: bool = false
#endregion

#region Health
@onready var health_bar = $health_bar
@export var max_health: float = 500
var health: float = 500 : set = set_health
#endregion

#region Stagger
@onready var stagger_timer = $stagger_timer
var stagger: bool = false
#endregion

#region Detection
var player: CharacterBody2D = null
var in_attack_range: bool = false
#endregion

#region Dealing Damage
@onready var enemy_area = $enemy_area
@onready var enemy_hitbox = $enemy_area/enemy_hitbox
@onready var cooldown_timer = $cooldown_timer
@onready var windup_timer = $windup_timer
@onready var hitbox_timer = $hitbox_timer

@export var dealing_damage: int = 10
@export var attack_duration: float = 0.15

var on_cooldown: bool = false
var is_attacking: bool = false
var hit_player: bool = false
#endregion

#region Grabbing
var is_grabbed: bool = false
#endregion

#region Freezing
var is_frozen: bool = false
var freeze_time_left: float = 0.0
#endregion

func _ready():
	health = max_health
	health_bar.init_health(health)
	health_bar.health_depleted.connect(_on_health_depleted)
	enemy_area.monitoring = false
	enemy_hitbox.disabled = true
	
	soft_collision = SoftCollision.new()
	soft_collision.radius = 20.0
	add_child(soft_collision)

func _physics_process(_delta: float) -> void:
	if is_grabbed:
		return
		
	if freeze_time_left > 0:
		freeze_time_left -= _delta
		velocity = Vector2.ZERO
		if freeze_time_left <= 0:
			unfreeze()
		return
	
	var target_velocity = Vector2.ZERO
	
	if player:
		if not stagger and not is_attacking:
			target_velocity = global_position.direction_to(player.global_position) * max_speed
		if in_attack_range and not on_cooldown and not stagger and not is_attacking:
			attack()
			
	invincibility = false
	
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * _delta)
	
	velocity = target_velocity + knockback_velocity
	
	if soft_collision and soft_collision.is_overlapping():
		velocity += soft_collision.get_push_vector() * soft_collision_strength
		
	move_and_slide()

func apply_freeze(duration: float) -> void:
	freeze_time_left = maxf(freeze_time_left, duration)
	
	if not is_frozen:
		is_frozen = true
		stagger = false
		stagger_timer.stop()
		
		if is_attacking:
			cancel_attack()

func unfreeze() -> void:
	is_frozen = false
	freeze_time_left = 0.0

func cancel_attack() -> void:
	is_attacking = false
	windup_timer.stop()
	hitbox_timer.stop()
	
	enemy_hitbox.set_deferred("disabled", true)
	enemy_area.set_deferred("monitoring", false)
	
	on_cooldown = true
	cooldown_timer.start()

func _is_player(body: Node) -> bool:
	return body.is_in_group("player") or "player" in body.name.to_lower()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if _is_player(body):
		player = body

func _on_detection_range_body_exited(body: Node2D) -> void:
	if _is_player(body):
		player = null

func _on_attack_range_body_entered(body: Node2D) -> void:
	if _is_player(body):
		in_attack_range = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	if _is_player(body):
		in_attack_range = false

func attack() -> void:
	is_attacking = true
	on_cooldown = true
	hit_player = false
	
	windup_timer.start()
	await windup_timer.timeout
	
	if is_frozen:
		return
	
	enemy_hitbox.disabled = false
	enemy_area.monitoring = true
	hitbox_timer.start()
	call_deferred("_check_initial_overlaps")

func _check_initial_overlaps() -> void:
	await get_tree().physics_frame
	if not enemy_area.monitoring:
		return
	for body in enemy_area.get_overlapping_bodies():
		_on_enemy_area_body_entered(body)

func _on_enemy_area_body_entered(body: Node) -> void:
	if hit_player:
		return
	if not body.has_method("take_damage"):
		return
	hit_player = true
	
	var knockback_dir = global_position.direction_to(body.global_position)
	var knockback_force = knockback_dir * knockback_strength
	
	body.take_damage(dealing_damage, knockback_force)

func _on_hitbox_timer_timeout() -> void:
	enemy_hitbox.disabled = true
	enemy_area.monitoring = false
	is_attacking = false
	cooldown_timer.start()

func _on_cooldown_timer_timeout() -> void:
	on_cooldown = false

func set_health(new_health: float) -> void:
	health = clamp(new_health, 0, max_health)
	if health_bar:
		health_bar.health = health

func take_damage(damage: float, knockback_force: Vector2 = Vector2.ZERO) -> void:
	health -= damage
	if is_grabbed or is_frozen:
		return
	
	stagger = true
	knockback_velocity = knockback_force
	stagger_timer.start()

func _on_health_depleted() -> void:
	randf()
	if Global.weapon_used == "String":
		if randf() <= 0.50:
			drop_bullet()
	self.queue_free()

func drop_bullet() -> void:
	pass

func _on_stagger_timer_timeout() -> void:
	stagger = false

func grabbed(release: bool) -> void:
	if release:
		Global.is_grabbing = false
		is_grabbed = false
		stagger = false
		knockback_velocity = Vector2.ZERO
		set_collision_layer_value(4, false)
	else:
		Global.is_grabbing = true
		is_grabbed = true
		set_collision_layer_value(4, true)
		knockback_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
