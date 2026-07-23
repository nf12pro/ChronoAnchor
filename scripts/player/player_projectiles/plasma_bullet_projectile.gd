extends Area2D

#region Dealing Damage
@export var damage: int = 100
@export var knockback_strength: float = 100.0
#endregion

#region Parrying / Direction
var direction: Vector2 = Vector2.RIGHT
var is_parried: bool = false
#endregion

#region Hitbox & Nodes
@onready var projectile_hitbox = $projectile_hitbox
@onready var sprite_2d = $sprite_2d
@onready var dissapear_timer = $dissapear_timer

var hit_enemies: Array = []
#endregion

var speed = 0

func _ready() -> void:
	projectile_hitbox.disabled = false
	dissapear_timer.start()
	
	call_deferred("_check_initial_overlaps")

func _check_initial_overlaps() -> void:
	await get_tree().physics_frame
	for body in get_overlapping_bodies():
		_damage_body(body)

func _on_body_entered(body: Node) -> void:
	_damage_body(body)

func _damage_body(body: Node) -> void:
	if body in hit_enemies:
		return
	
	if body.has_method("take_damage"):
		hit_enemies.append(body)
		var force = direction.normalized() * knockback_strength
		body.take_damage(damage, force)

func _on_dissapear_timer_timeout() -> void:
	queue_free()
