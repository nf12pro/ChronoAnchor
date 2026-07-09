extends Node2D

#region Collision Detection
@onready var sword_area = $sword_area
@onready var hitbox_timer = $hitbox_timer
@onready var cooldown_timer = $cooldown_timer

var on_cooldown: bool = false
#endregion

#region Generate Semi Circle
@export var radius: float = 100.0
@export var segments: int = 16
@onready var collision_polygon = $sword_area/sword_hitbox
#endregion

#region Dealing Damage
var hit_enemies: Array = []  

var basic_attack_damage: int = 20
var light_attack_damage: int = 10
var heavy_attack_damage: int = 30
#endregion

func _ready() -> void:
	sword_area.monitoring = false
	hitbox_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS

func _process(_delta: float) -> void:
	if Global.is_attacking:
		return
	var mouse_pos = get_global_mouse_position()
	global_rotation = (mouse_pos - global_position).angle()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and hitbox_timer.is_stopped():
		activate_hitbox()

func activate_hitbox() -> void:
	if on_cooldown:
		return
	Global.is_attacking = true
	cooldown_timer.start()
	on_cooldown = true
	generate_semi_circle()
	hit_enemies.clear()
	sword_area.monitoring = true        
	hitbox_timer.start()
	for body in sword_area.get_overlapping_bodies():  
		_on_sword_area_body_entered(body)

func generate_semi_circle() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	for i in range(segments + 1):
		var angle: float = deg_to_rad(-90.0 + (180.0 * i / segments))
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	collision_polygon.polygon = points 

func _on_sword_area_body_entered(body: Node) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage"):
		hit_enemies.append(body)
		body.take_damage(basic_attack_damage)
		Global.freeze(0.08, 0.02)

func _on_hitbox_timer_timeout() -> void:
	sword_area.monitoring = false
	Global.is_attacking = false
	collision_polygon.polygon = PackedVector2Array()  

func _on_cooldown_timer_timeout() -> void:
	on_cooldown = false
