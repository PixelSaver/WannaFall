extends Node3D
class_name LevelManager

@export var levels_arr : Array[Node3D]
var current_level 
var total_levels : int = 0

func _ready() -> void:
	total_levels = levels_arr.size()
	set_level(0)

func set_level(idx:int):
	if total_levels == 0: return
	if idx != clamp(idx, 0, total_levels): return
	if current_level:
		current_level.queue_free()
	var inst = levels_arr[idx].instantiate()
	add_child(inst)
	current_level = inst
