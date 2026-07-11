extends Area2D

@export var speed: float = 500.0
@export var damage: int = 10

var direction: Vector2 = Vector2.RIGHT
var is_parried: bool = false

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func parried() -> void:
	if is_parried:
		return 

	direction = -direction
	speed *= 1.5 
	
	rotation += PI 
	is_parried = true
	
	set_collision_mask_value(4, false) 
	set_collision_mask_value(5, true)
