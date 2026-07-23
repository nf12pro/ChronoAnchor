extends Area2D

func _on_body_entered(_body: Node2D) -> void:
	if Global.bullet_available == "None":
		Global.bullet_available = "Explosion"
	queue_free()
