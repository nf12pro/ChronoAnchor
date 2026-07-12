extends Node

#region General Variables
var is_dashing: bool = false
var is_attacking: bool = false
var on_windup: bool = false
var cancelled_attack: bool = false

var player_global_position : Vector2

var is_grabbing = false
#endregion

#region Camera
signal screenshake_requested(strength: float, duration: float)

func apply_screenshake(strength: float, duration: float = 0.5) -> void:
	screenshake_requested.emit(strength, duration)
#endregion

#region Hitstop/Freeze
var request_id: int = 0
var screen_shake_enabled: bool = true

func freeze(duration, scale) -> void:
	request_id += 1
	var my_id = request_id
	Engine.time_scale = scale
	var local_timer := get_tree().create_timer(duration, true, false, true)
	await local_timer.timeout
	if my_id == request_id:
		Engine.time_scale = 1
#endregion
