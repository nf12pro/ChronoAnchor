extends Area2D

@export var radius: float = 20.0

func _ready() -> void:
	var shape_node = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	shape_node.shape = circle_shape
	
	add_child(shape_node)

func is_overlapping() -> bool:
	return has_overlapping_areas()

func get_push_vector() -> Vector2:
	var areas = get_overlapping_areas()
	var push_vector = Vector2.ZERO
	if areas.size() > 0:
		for area in areas:
			var direction = area.global_position.direction_to(global_position)
			if direction == Vector2.ZERO:
				direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			push_vector += direction
		push_vector = push_vector.normalized()
		
	return push_vector
