extends CharacterBody2D

#region Movement
@export var max_speed: float = 100.0
#endregion

#region Invincibility
var invincibility: bool = false
#endregion

#region Health
@onready var health_bar = $health_bar
@export var max_health: float = 100
var health: float = 100 : set = set_health
#endregion

#region Detection
var player: CharacterBody2D = null

func _ready():
	health = max_health
	health_bar.init_health(health)
	health_bar.health_depleted.connect(_on_health_depleted)

func _physics_process(_delta: float) -> void:
	if player:
		velocity = global_position.direction_to(player.global_position) * max_speed
		move_and_slide()
	invincibility = false
	velocity = velocity.limit_length(max_speed)
	move_and_slide()

func _on_detection_range_area_entered(body):
	if body.name == "player":
		player = body

func _on_detection_range_area_exited(body):
	if body.name == "player":
		player = null
		velocity = Vector2.ZERO

func set_health(new_health: float) -> void:
	health = clamp(new_health, 0, max_health)
	if health_bar:
		health_bar.health = health

func _on_health_depleted() -> void:
	self.queue_free()
