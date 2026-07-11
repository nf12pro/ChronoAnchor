extends Area2D

#region Dealing Damage
@export var speed: float = 500.0
@export var damage: int = 10
@export var knockback_strength: float = 300.0
#endregion

#region Parrying
var direction: Vector2 = Vector2.RIGHT
var is_parried: bool = false
#endregion

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		var force = direction.normalized() * knockback_strength
		body.take_damage(damage, force)
	
	queue_free()

func parried() -> void:
	if is_parried:
		return 
	speed *= 1.15
	knockback_strength = 200
	direction = -direction
	
	rotation += PI 
	is_parried = true
	
	set_collision_mask_value(4, false) 
	set_collision_mask_value(5, true)
