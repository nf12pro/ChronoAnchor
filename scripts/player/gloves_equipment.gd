extends Node2D

#region gloves Timer
@onready var gloves_area = $gloves_area
@onready var hitbox_timer = $hitbox_timer
@onready var cooldown_timer = $cooldown_timer
@onready var windup_timer = $windup_timer

var on_cooldown: bool = false
#endregion

#region Gloves Hitbox
@onready var basic_gloves_hitbox = $gloves_area/basic_gloves_hitbox
@onready var heavy_gloves_hitbox = $gloves_area/heavy_gloves_hitbox
@onready var light_gloves_hitbox = $gloves_area/light_gloves_hitbox
#endregion

#region Gloves Attacks
var basic_gloves_attack: bool = false
var heavy_gloves_attack: bool = false
var light_gloves_attack: bool = false

@onready var player = get_parent()

var hit_enemies: Array = []

@export var basic_attack_damage: int = 20
@export var light_attack_damage: int = 15
@export var heavy_attack_damage: int = 30

@export var basic_knockback: float = 30.0
@export var light_knockback: float = 10.0
@export var heavy_knockback: float = 0.0
#endregion

#region Combo
@onready var combo_timer = $combo_timer

var combo_length: int = 3  

var active_combo_step: int = 0 
var combo_step: int = 0        
var combo_ready: bool = false
#endregion

#region Grabbing Mechanic
@onready var hold_point = $hold_point

@onready var held_enemy: CharacterBody2D = null
var is_holding: bool = false
#endregion

func _ready() -> void:
	gloves_area.monitoring = false
	basic_gloves_hitbox.disabled = true
	heavy_gloves_hitbox.disabled = true
	light_gloves_hitbox.disabled = true
 
func _process(_delta: float) -> void:
	if Global.is_attacking or Global.on_windup:
		return 
	if is_holding and held_enemy != null:
		if Global.grab_stop == false:
			held_enemy.global_position = hold_point.global_position
		
	var mouse_position = get_global_mouse_position() 
	global_rotation = (mouse_position - global_position).angle()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("basic_attack") and hitbox_timer.is_stopped() and Global.is_dashing and not on_cooldown:
		basic_gloves_attack = false
		heavy_gloves_attack = false
		light_gloves_attack = true
		combo_ready = false
		combo_step = 0
		combo_timer.stop()
		light_attack()
	elif event.is_action_pressed("basic_attack") and hitbox_timer.is_stopped() and (not on_cooldown or combo_ready):
		basic_gloves_attack = true
		heavy_gloves_attack = false
		light_gloves_attack = false
		basic_attack()
	elif event.is_action_pressed("heavy_attack") and hitbox_timer.is_stopped() and Global.is_dashing and not on_cooldown:
		basic_gloves_attack = false
		heavy_gloves_attack = true
		light_gloves_attack = false
		combo_ready = false
		combo_step = 0
		combo_timer.stop()
		await player.dash_finished
		heavy_attack()
	elif event.is_action_pressed("heavy_attack") and hitbox_timer.is_stopped() and not on_cooldown:
		basic_gloves_attack = false
		heavy_gloves_attack = true
		light_gloves_attack = false
		combo_ready = false
		combo_step = 0
		combo_timer.stop()
		heavy_attack()
 
func basic_attack() -> void:
	active_combo_step = combo_step if combo_ready else 0
	combo_ready = false
	combo_timer.stop()
	 
	Global.on_windup = true
	windup_timer.start(0.1)
	await windup_timer.timeout
	 
	Global.on_windup = false
	if Global.cancelled_attack:
		return
	
	hit_enemies.clear()
	Global.is_attacking = true
	on_cooldown = true
	
	if active_combo_step == 2:
		cooldown_timer.start(0.8)
	else:
		cooldown_timer.start() 
	
	basic_gloves_hitbox.disabled = false
	heavy_gloves_hitbox.disabled = true
	light_gloves_hitbox.disabled = true
	
	gloves_area.monitoring = true
	hitbox_timer.start(0.08)
	call_deferred("_check_initial_overlaps")
	
	combo_step = (active_combo_step + 1) % combo_length
	
	if combo_step != 0:
		combo_timer.start() 
		combo_ready = true
	else:
		combo_ready = false 

func light_attack() -> void:
	hit_enemies.clear()
	Global.is_attacking = true
	on_cooldown = true
	cooldown_timer.start(0.2)
	 
	basic_gloves_hitbox.disabled = true
	heavy_gloves_hitbox.disabled = true
	light_gloves_hitbox.disabled = false
	 
	gloves_area.monitoring = true
	hitbox_timer.start(0.06)
	call_deferred("_check_initial_overlaps")
 
func heavy_attack() -> void:
	Global.cancelled_attack = false
	Global.on_windup = true
	windup_timer.start(0.2)
	Global.freeze(0.01, 0.90)
	await windup_timer.timeout
	
	if Global.cancelled_attack:
		return
	
	hit_enemies.clear()
	Global.is_attacking = true
	on_cooldown = true
	cooldown_timer.start(2.0)
	
	basic_gloves_hitbox.disabled = true
	heavy_gloves_hitbox.disabled = false
	light_gloves_hitbox.disabled = true
	
	gloves_area.monitoring = true
	hitbox_timer.start(0.12)
	call_deferred("_check_initial_overlaps")
 
func _check_initial_overlaps() -> void:
	await get_tree().physics_frame
	if not gloves_area.monitoring:
		return
	for body in gloves_area.get_overlapping_bodies():
		_on_gloves_area_body_entered(body)
 
func _on_gloves_area_body_entered(body: Node) -> void:
	if body in hit_enemies:
		return
	if not body.has_method("take_damage"):
		return
 
	hit_enemies.append(body)
	var damage := basic_attack_damage
	var knockback_force := basic_knockback
	
	if light_gloves_attack: 
		damage = light_attack_damage
		knockback_force = light_knockback
		Global.freeze(0.035, 0.01)
	elif heavy_gloves_attack:
		damage = heavy_attack_damage
		knockback_force = heavy_knockback
		Global.freeze(0.10, 0.01)
		
		if not is_holding and body is CharacterBody2D:
			held_enemy = body
			is_holding = true
			if held_enemy.has_method("grabbed"):
				held_enemy.grabbed(3.0)
	else:
		damage = basic_attack_damage
		knockback_force = basic_knockback
		if active_combo_step == 1:
			print("COMBO 1")
			knockback_force = basic_knockback * 1.25
			damage = int(basic_attack_damage * 1.25)
			Global.freeze(0.02, 0.035)
		elif active_combo_step == 2:
			print("COMBO 2")
			knockback_force = basic_knockback * 1.50
			damage = int(basic_attack_damage * 1.50)
			Global.freeze(0.05, 0.05)
		else:
			print("FIRST HIT")
			Global.freeze(0.035, 0.02)
			
	var direction = global_position.direction_to(body.global_position)
	var force = direction * knockback_force
	body.take_damage(damage, force)
 
func _on_hitbox_timer_timeout() -> void:
	gloves_area.monitoring = false
	basic_gloves_hitbox.disabled = true
	heavy_gloves_hitbox.disabled = true
	light_gloves_hitbox.disabled = true
	basic_gloves_attack = false
	heavy_gloves_attack = false
	light_gloves_attack = false
	hit_enemies.clear()
	Global.is_attacking = false
 
func _on_cooldown_timer_timeout() -> void:
	on_cooldown = false
 
func _on_windup_timer_timeout() -> void:
	Global.on_windup = false
 
func _on_combo_timer_timeout() -> void:
	combo_ready = false
	combo_step = 0
