extends Node

#region General Variables
var is_dashing: bool = false
var is_attacking: bool = false
var on_windup: bool = false
var cancelled_attack: bool = false

var player_global_position : Vector2

var is_grabbing = false
#endregion

#region Hitstop/Freeze
var request_id: int = 0

func freeze(duration, scale) -> void:
	request_id += 1
	var my_id = request_id
	Engine.time_scale = scale
	var local_timer := get_tree().create_timer(duration, true, false, true)
	await local_timer.timeout
	if my_id == request_id:
		Engine.time_scale = 1
#endregion
