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

@onready var explosion_timer = $explosion_timer

var projectile_hitbox_active = true
var hit_enemies: Array = []
#endregion

#region Explosion
var timer_duration: float = 0.15
#endregion

#region Screen Shake
var explosion_force_screenshake: float = 0.60
var explosion_duration_screenshake: float = 0.75

var projectile_force_screenshake: float = 0.50
var projectile_duration_screenshake: float = 0.55
#endregion

func _ready() -> void:
	projectile_hitbox.disabled = false
	explosion_hitbox.disabled = true
	
	explosion_timer.start()

func _physics_process(delta: float) -> void:
	if projectile_hitbox_active:
		global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body in hit_enemies:
		return
	
	if body.has_method("take_damage"):
		hit_enemies.append(body) 
		var force = direction.normalized() * knockback_strength
		
		Global.apply_screenshake(projectile_force_screenshake, projectile_duration_screenshake)
		
		if projectile_hitbox_active:
			body.take_damage(damage, force)
		else:
			var multiplied_force = force * 1.5
			body.take_damage(damage, multiplied_force)
	
	if projectile_hitbox_active:
		explode()

func explode() -> void:
	projectile_hitbox_active = false
	sprite_2d.visible = false
	
	projectile_hitbox.set_deferred("disabled", true)
	explosion_hitbox.set_deferred("disabled", false)
	
	Global.apply_screenshake(explosion_force_screenshake, explosion_duration_screenshake)
	
	await get_tree().create_timer(timer_duration).timeout
	queue_free()

func _on_explosion_timer_timeout() -> void:
	explode()
