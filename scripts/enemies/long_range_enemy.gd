extends CharacterBody2D

#region Movement
@export var max_speed: float = 25.0
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
@export var max_health: float = 100
var health: float = 100 : set = set_health
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
@onready var cooldown_timer = $cooldown_timer
@onready var windup_timer = $windup_timer
@onready var hitbox_timer = $hitbox_timer

@export var dealing_damage: int = 10
@export var attack_duration: float = 0.15

var on_cooldown: bool = false
var is_attacking: bool = false
var hit_player: bool = false
#endregion

func _ready():
	health = max_health
	health_bar.init_health(health)
	health_bar.health_depleted.connect(_on_health_depleted)
	
	soft_collision = SoftCollision.new()
	soft_collision.radius = 20.0 
	add_child(soft_collision)

func _physics_process(_delta: float) -> void:
	look_at(Global.player_global_position)
	if player:
		if not stagger and not is_attacking:
			velocity = global_position.direction_to(player.global_position) * max_speed
		else:
			velocity = Vector2.ZERO
		if in_attack_range and not on_cooldown and not stagger and not is_attacking:
			attack()
	else:
		velocity = Vector2.ZERO
	invincibility = false
	velocity = velocity.limit_length(max_speed)
	
	if soft_collision and soft_collision.is_overlapping():
		velocity += soft_collision.get_push_vector() * soft_collision_strength
		
	move_and_slide()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.name == "player":
		player = body

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.name == "player":
		player = null

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.name == "player":
		in_attack_range = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.name == "player":
		in_attack_range = false

func attack() -> void:
	is_attacking = true
	on_cooldown = true
	hit_player = false

	windup_timer.start()
	await windup_timer.timeout
	hitbox_timer.start()
	call_deferred("_check_initial_overlaps")

func _check_initial_overlaps() -> void:
	await get_tree().physics_frame
	return

func _on_hitbox_timer_timeout() -> void:
	is_attacking = false
	cooldown_timer.start()

func _on_cooldown_timer_timeout() -> void:
	on_cooldown = false

func set_health(new_health: float) -> void:
	health = clamp(new_health, 0, max_health)
	if health_bar:
		health_bar.health = health

func take_damage(damage):
	health -= damage
	stagger = true
	stagger_timer.start()

func _on_health_depleted() -> void:
	self.queue_free()

func _on_stagger_timer_timeout() -> void:
	stagger = false
