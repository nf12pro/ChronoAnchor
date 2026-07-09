extends Node2D

#region Semi Cirle Generation
@onready var collision_polygon: CollisionPolygon2D = $sword_area/sword_hitbox

@export var radius: float = 80.0
@export var segments: int = 16
#endregion

#region Damaging Opponent 
@onready var hitbox_timer = $hitbox_timer

var enemy = null
var damage = 20
#endregion

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		generate_semi_circle()
		hitbox_timer.start()

func generate_semi_circle() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	for i in range(segments + 1):
		var angle: float = deg_to_rad(-90.0 + (180.0 * i / segments))
		var x: float = cos(angle) * radius
		var y: float = sin(angle) * radius
		points.append(Vector2(x, y))
	collision_polygon.polygon = points

func _on_sword_area_body_entered(body):
	enemy = body
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		Global.freeze(0.08, 0.02)
