extends CharacterBody2D

#region Movement
@export var max_speed: float = 25.0
#endregion

#region Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 600.0
#endregion

#region Soft Collision
const SoftCollision = preload("res://scripts/systems/soft_collision.gd")
var soft_collision: Area2D
@export var soft_collision_strength: float = 120.0
#endregion

#region Health
@onready var health_bar = $health_bar
@export var max_health: float = 100
var health: float = 100 : set = set_health
#endregion

#region Stagger
@onready var stagger_timer = $stagger_timer
var stagger: bool = false
#endregion

#region Detection
@onready var detection_range = $detection_range
@onready var attack_range = $attack_range
@onready var too_close_range = $too_close_range

var player: CharacterBody2D = null
var in_attack_range: bool = false
var too_close: bool = false
#endregion

#region Ranged Attack
@onready var cooldown_timer = $cooldown_timer
@onready var windup_timer = $windup_timer
@onready var hitbox_timer = $hitbox_timer

const Projectile = preload("res://scenes/enemies/enemy_projectiles/long_range_enemy_projectile.tscn")

@export var dealing_damage: int = 10
@export var projectile_speed: float = 500.0
@export var projectile_spawn_offset: float = 30.0

var on_cooldown: bool = false
var is_attacking: bool = false
var is_winding_up: bool = false
#endregion

func _ready():
	health = max_health
	health_bar.init_health(health)
	health_bar.health_depleted.connect(_on_health_depleted)

	soft_collision = SoftCollision.new()
	soft_collision.radius = 20.0
	add_child(soft_collision)

	call_deferred("_check_initial_overlaps")

func _check_initial_overlaps() -> void:
	await get_tree().physics_frame
	for body in detection_range.get_overlapping_bodies():
		if body.name == "player_sword" or "player_gloves":
			player = body
	for body in attack_range.get_overlapping_bodies():
		if body.name == "player_sword" or "player_gloves":
			in_attack_range = true
	for body in too_close_range.get_overlapping_bodies():
		if body.name == "player_sword" or "player_gloves":
			too_close = true

func _physics_process(_delta: float) -> void:
	if player and not is_winding_up:
		look_at(player.global_position)
	
	var target_velocity = Vector2.ZERO
	
	if player and not stagger and not is_attacking:
		if too_close:
			target_velocity = player.global_position.direction_to(global_position) * max_speed
		elif not in_attack_range:
			target_velocity = global_position.direction_to(player.global_position) * max_speed
	
	if player and in_attack_range and not on_cooldown and not stagger and not is_attacking:
		attack()
	
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * _delta)
	
	velocity = target_velocity + knockback_velocity
	
	if soft_collision and soft_collision.is_overlapping():
		velocity += soft_collision.get_push_vector() * soft_collision_strength
	
	move_and_slide()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.name == "player_sword" or "player_gloves":
		player = body

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.name == "player_sword" or "player_gloves":
		player = null

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.name == "player_sword" or "player_gloves":
		in_attack_range = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.name == "player_sword" or "player_gloves":
		in_attack_range = false

func _on_too_close_range_body_entered(body: Node2D) -> void:
	if body.name == "player_sword" or "player_gloves":
		too_close = true

func _on_too_close_range_body_exited(body: Node2D) -> void:
	if body.name == "player_sword" or "player_gloves":
		too_close = false

func attack() -> void:
	is_attacking = true
	is_winding_up = true
	on_cooldown = true
	velocity = Vector2.ZERO

	windup_timer.start()
	await windup_timer.timeout

	is_winding_up = false

	if not stagger:
		fire_projectile()

	hitbox_timer.start()

func fire_projectile() -> void:
	var projectile = Projectile.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2.RIGHT.rotated(rotation) * projectile_spawn_offset
	projectile.rotation = rotation
	projectile.direction = Vector2.RIGHT.rotated(rotation)
	projectile.damage = dealing_damage
	projectile.speed = projectile_speed

func _on_hitbox_timer_timeout() -> void:
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
	stagger = true
	knockback_velocity = knockback_force
	stagger_timer.start()

func _on_health_depleted() -> void:
	self.queue_free()

func _on_stagger_timer_timeout() -> void:
	stagger = false
