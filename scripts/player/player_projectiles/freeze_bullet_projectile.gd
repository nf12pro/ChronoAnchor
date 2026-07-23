extends Area2D

#region Dealing Damage
@export var speed: float = 350.0
@export var damage: int = 25
@export var knockback_strength: float = 100.0
@export var freeze_duration: float = 1.00
#endregion

#region Parrying
var direction: Vector2 = Vector2.RIGHT
var is_parried: bool = false
#endregion

#region Hitbox
@onready var projectile_hitbox = $projectile_hitbox
@onready var area_hitbox = $area_hitbox
@onready var sprite_2d = $sprite_2d

@onready var explosion_timer = $explosion_timer

var projectile_hitbox_active = true
var hit_enemies: Array = []
#endregion

func _ready() -> void:
	projectile_hitbox.disabled = false
	area_hitbox.disabled = true
	
	explosion_timer.start()

func _physics_process(delta: float) -> void:
	if projectile_hitbox_active:
		global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body in hit_enemies:
		return
	
	var touched_enemy: bool = false
	
	if body.has_method("apply_freeze"):
		touched_enemy = true
		body.apply_freeze(freeze_duration)

	if body.has_method("take_damage"):
		touched_enemy = true
		var force = direction.normalized() * knockback_strength
		
		if projectile_hitbox_active:
			body.take_damage(damage, force)
		else:
			body.take_damage(damage, force * 1.5)
	
	if touched_enemy:
		hit_enemies.append(body)
	
	if projectile_hitbox_active:
		explode()

func explode() -> void:
	projectile_hitbox_active = false
	sprite_2d.visible = false
	
	projectile_hitbox.set_deferred("disabled", true)
	area_hitbox.set_deferred("disabled", false)
	
	await get_tree().create_timer(0.15).timeout
	queue_free()

func _on_explosion_timer_timeout() -> void:
	explode()
