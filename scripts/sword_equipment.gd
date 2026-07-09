extends Node2D

#region Collision Detection
@onready var sword_area = $sword_area
@onready var hitbox_timer = $hitbox_timer
@onready var cooldown_timer = $cooldown_timer

var on_cooldown: bool = false
#endregion

#region Hitbox
@export var radius: float = 100.0
@export var segments: int = 16

@onready var basic_sword_hitbox = $sword_area/basic_sword_hitbox
@onready var heavy_sword_hitbox = $sword_area/heavy_sword_hitbox
@onready var light_sword_hitbox = $sword_area/light_sword_hitbox

var basic_sword_attack: bool = false
var heavy_sword_attack: bool = false
var light_sword_attack: bool = false
#endregion

#region Dealing Damage
var hit_enemies: Array = []  

var basic_attack_damage: int = 20
var light_attack_damage: int = 10
var heavy_attack_damage: int = 30
#endregion

func _ready() -> void:
	sword_area.monitoring = false
	generate_semi_circle()

func generate_semi_circle() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	for i in range(segments + 1):
		var angle: float = deg_to_rad(-90.0 + (180.0 * i / segments))
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	heavy_sword_hitbox.polygon = points 

func _process(_delta: float) -> void:
	if Global.is_attacking:
		return
	var mouse_pos = get_global_mouse_position()
	global_rotation = (mouse_pos - global_position).angle()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("basic_attack") and hitbox_timer.is_stopped() and Global.is_dashing and not on_cooldown:
		light_attack()
		basic_sword_attack = false
		heavy_sword_attack = false
		light_sword_attack = true
	elif event.is_action_pressed("basic_attack") and hitbox_timer.is_stopped() and not on_cooldown:
		basic_attack()
		basic_sword_attack = true
		heavy_sword_attack = false
		light_sword_attack = false
	elif event.is_action_pressed("heavy_atttack") and hitbox_timer.is_stopped() and not on_cooldown:
		heavy_attack()
		basic_sword_attack = false
		heavy_sword_attack = true
		light_sword_attack = false

func basic_attack() -> void:
	Global.is_attacking = true
	cooldown_timer.start(0.4)
	on_cooldown = true
	
	basic_sword_hitbox.disabled = false
	heavy_sword_hitbox.disabled = true
	light_sword_hitbox.disabled = true
	
	sword_area.monitoring = true 
	hitbox_timer.start(0.08)
	
	for body in sword_area.get_overlapping_bodies():  
		_on_sword_area_body_entered(body)

func light_attack() -> void:
	Global.is_attacking = true
	cooldown_timer.start(0.25)
	on_cooldown = true
	
	basic_sword_hitbox.disabled = true
	heavy_sword_hitbox.disabled = true
	light_sword_hitbox.disabled = false
	
	sword_area.monitoring = true 
	hitbox_timer.start(0.05)
	
	for body in sword_area.get_overlapping_bodies():  
		_on_sword_area_body_entered(body)

func heavy_attack() -> void:
	Global.is_attacking = true
	cooldown_timer.start(0.6)
	on_cooldown = true
	
	basic_sword_hitbox.disabled = true
	heavy_sword_hitbox.disabled = false
	light_sword_hitbox.disabled = true
	
	sword_area.monitoring = true 
	hitbox_timer.start(0.12)
	
	for body in sword_area.get_overlapping_bodies():  
		_on_sword_area_body_entered(body)

func _on_sword_area_body_entered(body: Node) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage"):
		hit_enemies.append(body)
		body.take_damage(basic_attack_damage)
		if light_sword_attack:
			Global.freeze(0.04, 0.035)
		elif basic_sword_attack:
			Global.freeze(0.05, 0.02)
		elif heavy_sword_attack:
			Global.freeze(0.075, 0.01)

func _on_hitbox_timer_timeout() -> void:
	sword_area.monitoring = false
	Global.is_attacking = false
	basic_sword_hitbox.disabled = true
	heavy_sword_hitbox.disabled = true
	light_sword_hitbox.disabled = true

func _on_cooldown_timer_timeout() -> void:
	on_cooldown = false
