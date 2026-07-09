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

#region Stagger
@onready var stagger_timer = $stagger_timer
var stagger: bool = false
#endregion

#region Detection
var player: CharacterBody2D = null
#endregion

func _ready():
	health = max_health
	health_bar.init_health(health)
	health_bar.health_depleted.connect(_on_health_depleted)

func _physics_process(_delta: float) -> void:
	if player:
		if not stagger:
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

func take_damage(damage):
	health -= damage
	stagger = true
	stagger_timer.start()

func _on_health_depleted() -> void:
	self.queue_free()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("take_damage_test"):
		health -= 20

func _on_stagger_timer_timeout() -> void:
	stagger = false
