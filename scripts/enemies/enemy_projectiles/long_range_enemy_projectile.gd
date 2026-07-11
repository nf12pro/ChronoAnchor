extends Area2D

#region Movement
@export var max_speed: float = 25.0
#endregion

#region Dealing Damage
@onready var enemy_area = $enemy_area
@onready var enemy_hitbox = $enemy_area/enemy_hitbox
@onready var cooldown_timer = $cooldown_timer
@onready var windup_timer = $windup_timer
@onready var hitbox_timer = $hitbox_timer

@export var dealing_damage: int = 10
@export var attack_duration: float = 0.15

var on_cooldown: bool = false
var is_attacking: bool = false
var hit_player: bool = false
#endregion

func _ready():
	enemy_area.monitoring = false
	enemy_hitbox.disabled = true

func _physics_process(_delta: float) -> void:
	pass

func _on_body_entered(body) -> void:
	if body.name == "player":
		body.take_damage(dealing_damage)
		self.queue_free()
