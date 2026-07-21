extends Area2D

#region Dealing Damage
@export var speed: float = 500.0
@export var damage: int = 50
@export var knockback_strength: float = 500.0
#endregion

#region Parrying
var direction: Vector2 = Vector2.RIGHT
var is_parried: bool = false
#endregion

#region Hitbox
@onready var projectile_hitbox = $projectile_hitbox
@onready var explosion_hitbox = $explosion_hitbox
@onready var sprite_2d = $sprite_2d

var projectile_hitbox_active = true
var hit_enemies: Array = []
#endregion

func _ready() -> void:
	projectile_hitbox.disabled = false
	explosion_hitbox.disabled = true

func _physics_process(delta: float) -> void:
	if projectile_hitbox_active:
		global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body in hit_enemies:
		return
	
	if body.has_method("take_damage"):
		hit_enemies.append(body) 
		var force = direction.normalized() * knockback_strength
		
		if projectile_hitbox_active:
			body.take_damage(damage, force)
		else:
			body.take_damage(damage, force * 1.5)
	
	if projectile_hitbox_active:
		explode()

func explode() -> void:
	projectile_hitbox_active = false
	sprite_2d.visible = false
	
	projectile_hitbox.set_deferred("disabled", true)
	explosion_hitbox.set_deferred("disabled", false)
	
	await get_tree().create_timer(0.15).timeout
	queue_free()
