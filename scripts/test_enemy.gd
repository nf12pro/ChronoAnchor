extends CharacterBody2D

#region Movement
@export var max_speed: float = 25.0
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
	else:
		velocity = Vector2.ZERO 
	invincibility = false
	velocity = velocity.limit_length(max_speed)
	move_and_slide()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.name == "player":
		player = body

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.name == "player":
		player = null

func set_health(new_health: float) -> void:
	health = clamp(new_health, 0, max_health)
	if health_bar:
		health_bar.health = health

func _on_health_depleted() -> void:
	self.queue_free()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("take_damage_test"):
		health -= 20
