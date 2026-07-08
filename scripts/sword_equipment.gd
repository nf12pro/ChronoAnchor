extends Node2D

@export var radius: float = 80.0
@export var segments: int = 16

@onready var collision_polygon: CollisionPolygon2D = $sword_area/sword_hitbox

func _ready() -> void:
	generate_semi_circle()

func generate_semi_circle() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	
	points.append(Vector2.ZERO)
	
	for i in range(segments + 1):
		var angle: float = deg_to_rad(-90.0 + (180.0 * i / segments))
		var x: float = cos(angle) * radius
		var y: float = sin(angle) * radius
		points.append(Vector2(x, y))
		
	collision_polygon.polygon = points
