extends Node2D

#region Gun Timer
@onready var gun_area = $gun_area
@onready var hitbox_timer = $hitbox_timer
@onready var cooldown_timer = $cooldown_timer
@onready var windup_timer = $windup_timer

var on_cooldown: bool = false
#endregion

#region Gun Hitbox
@onready var basic_gun_hitbox = $gun_area/basic_gun_hitbox
@onready var light_gun_hitbox = $gun_area/light_gun_hitbox
#endregion

#region Gun Attacks
var basic_gun_attack: bool = false
var heavy_gun_attack: bool = false
var light_gun_attack: bool = false

@onready var player = get_parent()

var hit_enemies: Array = []

@export var basic_attack_damage: int = 20
@export var light_attack_damage: int = 10

@export var basic_knockback: float = 150.0
@export var light_knockback: float = 400.0
#endregion

#region Input Buffering
@export var buffer_window: float = 0.15
var basic_attack_buffer: float = 0.0
var heavy_attack_buffer: float = 0.0
#endregion

#region Heavy Attack
const Projectile = preload("res://scenes/player/player_projectiles/freeze_bullet_projectile.tscn")

@export var projectile_speed: float = 500.0
@export var projectile_spawn_offset: float = 30.0
#endregion

func _ready() -> void:
	gun_area.monitoring = false
	basic_gun_hitbox.disabled = true
	light_gun_hitbox.disabled = true

func _process(delta: float) -> void:
	if basic_attack_buffer > 0.0: basic_attack_buffer -= delta
	if heavy_attack_buffer > 0.0: heavy_attack_buffer -= delta
	
	if basic_attack_buffer > 0.0:
		if hitbox_timer.is_stopped() and Global.is_dashing and not on_cooldown:
			basic_attack_buffer = 0.0
			basic_gun_attack = false
			heavy_gun_attack = false
			light_gun_attack = true
			light_attack()
		elif hitbox_timer.is_stopped() and not on_cooldown:
			basic_attack_buffer = 0.0
			basic_gun_attack = true
			heavy_gun_attack = false
			light_gun_attack = false
			basic_attack()
			
	if heavy_attack_buffer > 0.0:
		if hitbox_timer.is_stopped() and Global.is_dashing and not on_cooldown:
			heavy_attack_buffer = 0.0
			basic_gun_attack = false
			heavy_gun_attack = true
			light_gun_attack = false
			_execute_heavy_dash_attack()
		elif hitbox_timer.is_stopped() and not on_cooldown:
			heavy_attack_buffer = 0.0
			basic_gun_attack = false
			heavy_gun_attack = true
			light_gun_attack = false
			heavy_attack()

	if Global.is_attacking or Global.on_windup:
		return 
	var mouse_position = get_global_mouse_position() 
	global_rotation = (mouse_position - global_position).angle()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("basic_attack"):
		basic_attack_buffer = buffer_window
	elif event.is_action_pressed("heavy_attack"):
		heavy_attack_buffer = buffer_window

func _execute_heavy_dash_attack() -> void:
	await player.dash_finished
	heavy_attack()

func basic_attack() -> void:
	Global.on_windup = true
	windup_timer.start()
	await windup_timer.timeout
	
	Global.on_windup = false
	hit_enemies.clear()
	Global.is_attacking = true
	on_cooldown = true
	cooldown_timer.start()
	
	basic_gun_hitbox.disabled = false
	light_gun_hitbox.disabled = true
	
	gun_area.monitoring = true
	hitbox_timer.start()
	call_deferred("_check_initial_overlaps")

func light_attack() -> void:
	hit_enemies.clear()
	Global.is_attacking = true
	on_cooldown = true
	cooldown_timer.start(0.25)
	
	basic_gun_hitbox.disabled = true
	light_gun_hitbox.disabled = false
	
	gun_area.monitoring = true
	hitbox_timer.start(0.05)
	call_deferred("_check_initial_overlaps")

func heavy_attack() -> void:
	Global.cancelled_attack = false
	Global.on_windup = true
	windup_timer.start(0.05)
	await windup_timer.timeout
	
	if Global.cancelled_attack:
		return
	
	Global.apply_screenshake(0.5)
	Global.freeze(0.01, 0.80)
	
	var projectile = Projectile.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector2.RIGHT.rotated(rotation) * projectile_spawn_offset
	projectile.rotation = rotation
	projectile.direction = Vector2.RIGHT.rotated(rotation)
	projectile.speed = projectile_speed
	
	hit_enemies.clear()
	Global.is_attacking = true
	on_cooldown = true
	cooldown_timer.start()
	
	basic_gun_hitbox.disabled = true
	light_gun_hitbox.disabled = true
	gun_area.monitoring = false
	
	hitbox_timer.start(0.12)

func _check_initial_overlaps() -> void:
	await get_tree().physics_frame
	if not gun_area.monitoring:
		return
	for body in gun_area.get_overlapping_bodies():
		_on_gun_area_body_entered(body)

func _on_gun_area_body_entered(body: Node) -> void:
	if body in hit_enemies:
		return
	if not body.has_method("take_damage"):
		return
	
	hit_enemies.append(body)
	var damage := basic_attack_damage
	var knockback_force := basic_knockback
	
	if light_gun_attack: 
		damage = light_attack_damage
		knockback_force = light_knockback
		Global.freeze(0.035, 0.03)
	else:
		damage = basic_attack_damage
		knockback_force = basic_knockback
		Global.freeze(0.05, 0.015)
		
	var direction = global_position.direction_to(body.global_position)
	var force = direction * knockback_force
	body.take_damage(damage, force)

func _on_hitbox_timer_timeout() -> void:
	gun_area.monitoring = false
	basic_gun_hitbox.disabled = true
	light_gun_hitbox.disabled = true
	basic_gun_attack = false
	heavy_gun_attack = false
	light_gun_attack = false
	hit_enemies.clear()
	Global.is_attacking = false

func _on_cooldown_timer_timeout() -> void:
	on_cooldown = false

func _on_windup_timer_timeout() -> void:
	Global.on_windup = false
